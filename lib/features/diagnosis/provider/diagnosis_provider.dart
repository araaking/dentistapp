import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/data/consultation_payload.dart';
import '../../../core/data/repositories/question_repository.dart';
import '../../../core/data/repositories/consultation_repository.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/models/question_model.dart';
import '../../../core/utils/constants.dart';

enum DiagnosisStage { sq, eq, finished }

enum DiagnosisState { initial, loading, loaded, error }

/// Status pengiriman konsultasi ke server.
enum SubmissionState { idle, submitting, success, error }

class DiagnosisProvider extends ChangeNotifier {
  final QuestionRepository _questionRepository;
  final ConsultationRepository _consultationRepository;

  DiagnosisProvider(this._questionRepository, this._consultationRepository);

  // State Variables
  DiagnosisState _state = DiagnosisState.initial;
  DiagnosisStage _stage = DiagnosisStage.sq;

  List<QuestionModel> _sqQuestions = [];
  List<QuestionModel> _eqQuestions = [];
  int _currentIndex = 0;
  String _errorMessage = '';

  // Validasi / error input untuk pertanyaan saat ini
  String? _validationError;
  String? _photoError;

  // Pengiriman konsultasi (dimiliki sepenuhnya oleh provider ini)
  SubmissionState _submissionState = SubmissionState.idle;
  String _submissionError = '';
  Map<String, dynamic>? _submissionResult;
  int _generation = 0; // naik setiap reset agar hasil lama diabaikan

  // Storing answers
  final Map<String, dynamic> _answers = {};

  // Getters for UI
  DiagnosisState get state => _state;
  DiagnosisStage get stage => _stage;
  String get errorMessage => _errorMessage;
  int get currentQuestionNumber => _currentIndex + 1;
  int get totalQuestions => _getCurrentQuestionList().length;
  QuestionModel? get currentQuestion {
    final currentList = _getCurrentQuestionList();
    if (currentList.isNotEmpty && _currentIndex < currentList.length) {
      return currentList[_currentIndex];
    }
    return null;
  }

  Map<String, dynamic> get answers => _answers;
  List<String> get sqCodes => _sqQuestions.map((q) => q.code).toList();
  List<String> get eqCodes => _eqQuestions.map((q) => q.code).toList();

  String? get validationError => _validationError;
  String? get photoError => _photoError;

  SubmissionState get submissionState => _submissionState;
  String get submissionError => _submissionError;
  Map<String, dynamic>? get submissionResult => _submissionResult;

  // Helper to get the correct question list based on the stage
  List<QuestionModel> _getCurrentQuestionList() {
    return _stage == DiagnosisStage.sq ? _sqQuestions : _eqQuestions;
  }

  Future<void> fetchQuestions() async {
    if (_sqQuestions.isNotEmpty) return; // Prevent re-fetching
    if (_state == DiagnosisState.loading) return;
    _state = DiagnosisState.loading;
    notifyListeners();
    final generation = _generation;
    try {
      final allQuestions = await _questionRepository.getQuestions();
      if (generation != _generation) return;
      _sqQuestions = allQuestions.sq;
      _eqQuestions = allQuestions.eq;
      _applyDefaultAnswers();
      _state =
          _sqQuestions.isEmpty ? DiagnosisState.error : DiagnosisState.loaded;
      _errorMessage = _sqQuestions.isEmpty ? 'Pertanyaan tidak ditemukan.' : '';
    } catch (e) {
      if (generation != _generation) return;
      _state = DiagnosisState.error;
      _errorMessage = ApiException.messageOf(e);
    } finally {
      notifyListeners();
    }
  }

  /// Mengisi jawaban awal dari `input.default` agar payload selalu lengkap dan
  /// sama dengan form web. Jawaban yang sudah ada tidak ditimpa.
  void _applyDefaultAnswers() {
    for (final q in [..._sqQuestions, ..._eqQuestions]) {
      if (_answers.containsKey(q.code)) continue;
      final input = q.input;
      switch (input.type) {
        case 'group_select_scores':
          final areas = input.areas ?? const <String>[];
          if (areas.isEmpty) break;
          final fallback = input.min ?? 0;
          final def = input.defaultValue;
          final scores = <String, int>{};
          for (final area in areas) {
            int? score;
            if (def is Map && def[area] is num) {
              score = (def[area] as num).toInt();
            } else if (def is num) {
              score = def.toInt();
            }
            scores[area] = score ?? fallback;
          }
          _answers[q.code] = scores;
          break;
        case 'composite':
          // E2 (bukaan mulut + foto) tidak punya default; wajib diisi pengguna.
          break;
        default:
          final defaultAnswer = input.defaultValue;
          if (defaultAnswer != null && defaultAnswer.toString().isNotEmpty) {
            _answers[q.code] = defaultAnswer.toString();
          }
      }
    }
  }

  void answerQuestion(String code, dynamic answer) {
    _answers[code] = answer;
    _validationError = null;
    notifyListeners();
  }

  /// Menyimpan teks bukaan mulut (E2) apa adanya; divalidasi saat lanjut.
  void setOpeningMm(String raw) {
    final current = _answers['E2'];
    final updated = current is Map
        ? Map<String, dynamic>.from(current)
        : <String, dynamic>{};
    updated['opening_mm'] = raw;
    _answers['E2'] = updated;
    _validationError = null;
    notifyListeners();
  }

  /// Validasi bukaan mulut: angka 0-100 (aturan server). Null bila valid.
  static String? validateOpeningMm(dynamic raw) {
    final text = raw?.toString().trim() ?? '';
    if (text.isEmpty) {
      return 'Masukkan bukaan mulut dalam angka (mm).';
    }
    final value = ConsultationPayload.parseOpeningMm(raw);
    if (value == null) {
      return 'Bukaan mulut harus berupa angka, mis. 40.';
    }
    if (value < 0 || value > 100) {
      return 'Bukaan mulut harus antara 0 dan 100 mm.';
    }
    return null;
  }

  /// Pesan validasi untuk pertanyaan saat ini, atau null bila boleh lanjut.
  String? validateCurrentQuestion() {
    final q = currentQuestion;
    if (q == null) return null;
    if (_stage == DiagnosisStage.eq && q.code == 'E2') {
      final e2 = _answers['E2'];
      final raw = e2 is Map ? e2['opening_mm'] : null;
      return validateOpeningMm(raw);
    }
    return null;
  }

  /// Lanjut ke pertanyaan berikutnya. Mengembalikan false bila jawaban saat
  /// ini belum valid (pesannya ada di [validationError]).
  /// Di pertanyaan terakhir hanya berpindah ke tahap `finished`; pengiriman
  /// dilakukan terpisah lewat [submitConsultation].
  bool nextQuestion() {
    if (_stage == DiagnosisStage.finished) return true;

    final error = validateCurrentQuestion();
    if (error != null) {
      _validationError = error;
      notifyListeners();
      return false;
    }
    _validationError = null;

    final currentList = _getCurrentQuestionList();
    if (_currentIndex < currentList.length - 1) {
      _currentIndex++;
    } else if (_stage == DiagnosisStage.sq) {
      if (_eqQuestions.isEmpty) {
        _stage = DiagnosisStage.finished;
      } else {
        _stage = DiagnosisStage.eq;
        _currentIndex = 0;
      }
    } else {
      _stage = DiagnosisStage.finished;
    }
    notifyListeners();
    return true;
  }

  void previousQuestion() {
    _validationError = null;
    if (_currentIndex > 0) {
      _currentIndex--;
    } else {
      if (_stage == DiagnosisStage.eq) {
        _stage = DiagnosisStage.sq;
        _currentIndex = _sqQuestions.length - 1;
      }
    }
    notifyListeners();
  }

  // --- EQ Specific Methods ---
  Future<void> takePictureForEQ2({ImagePicker? picker}) async {
    _photoError = null;
    try {
      final XFile? photo = await (picker ?? ImagePicker()).pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
      );
      if (photo == null) return;

      final File photoFile = File(photo.path);
      final size = await photoFile.length();
      if (size > AppConstants.maxPhotoBytes) {
        _photoError =
            'Ukuran foto melebihi 5 MB. Silakan ambil ulang foto dengan resolusi lebih rendah.';
        notifyListeners();
        return;
      }

      final current = _answers['E2'];
      final updated = current is Map
          ? Map<String, dynamic>.from(current)
          : <String, dynamic>{};
      updated['photo'] = photoFile; // File dikirim sebagai multipart
      _answers['E2'] = updated;
      notifyListeners();
    } catch (_) {
      _photoError =
          'Gagal mengambil foto. Pastikan izin kamera telah diberikan.';
      notifyListeners();
    }
  }

  /// Mengosongkan semua jawaban, pertanyaan, dan hasil (diagnosis baru/logout).
  void resetDiagnosis() {
    _generation++;
    _state = DiagnosisState.initial;
    _stage = DiagnosisStage.sq;
    _currentIndex = 0;
    _answers.clear();
    _sqQuestions = [];
    _eqQuestions = [];
    _errorMessage = '';
    _validationError = null;
    _photoError = null;
    _submissionState = SubmissionState.idle;
    _submissionError = '';
    _submissionResult = null;
    notifyListeners();
  }

  /// Alias untuk [resetDiagnosis]; dipakai saat logout / sesi berakhir.
  void clear() => resetDiagnosis();

  /// Membangun payload konsultasi dari jawaban saat ini (satu kali, dipakai
  /// oleh [submitConsultation]).
  ConsultationPayload buildPayload() {
    return ConsultationPayload.fromAnswers(
      answers: _answers,
      sqCodes: sqCodes,
      eqCodes: eqCodes,
    );
  }

  /// Mengirim konsultasi tepat satu kali. Panggilan saat sedang mengirim atau
  /// setelah berhasil diabaikan; setelah gagal boleh dicoba lagi.
  Future<void> submitConsultation() async {
    if (_submissionState == SubmissionState.submitting ||
        _submissionState == SubmissionState.success) {
      return;
    }
    _submissionState = SubmissionState.submitting;
    _submissionError = '';
    notifyListeners();
    final generation = _generation;

    try {
      final result =
          await _consultationRepository.submitConsultation(buildPayload());
      if (generation != _generation) return;
      _submissionResult = result;
      _submissionState = SubmissionState.success;
    } catch (e) {
      if (generation != _generation) return;
      _submissionError = ApiException.messageOf(e);
      _submissionState = SubmissionState.error;
    }
    notifyListeners();
  }
}

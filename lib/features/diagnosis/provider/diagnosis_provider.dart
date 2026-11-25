import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/data/consultation_payload.dart';
import '../../../core/data/repositories/consultation_repository.dart';
import '../../../core/data/repositories/question_repository.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/models/consultation.dart';
import '../../../core/models/question_model.dart';
import '../../../core/utils/constants.dart';

enum DiagnosisStage { sq, eq, finished }

enum DiagnosisState { initial, loading, loaded, error }

/// Status pengiriman konsultasi ke server.
enum SubmissionState { idle, submitting, success, error }

/// Mengelola alur pemeriksaan mandiri: daftar pertanyaan (SQ lalu EQ) sebagai
/// satu urutan langkah, jawaban pengguna, validasi, dan pengiriman.
///
/// Tidak ada jawaban yang diisi otomatis: setiap langkah harus dijawab
/// pengguna sendiri agar hasil skrining mencerminkan kondisi sebenarnya.
class DiagnosisProvider extends ChangeNotifier {
  final QuestionRepository _questionRepository;
  final ConsultationRepository _consultationRepository;

  /// Dipanggil sekali setelah konsultasi berhasil tersimpan (mis. untuk
  /// menyegarkan riwayat).
  final VoidCallback? onSubmitted;

  DiagnosisProvider(
    this._questionRepository,
    this._consultationRepository, {
    this.onSubmitted,
  });

  /// Kode pertanyaan pengukuran bukaan mulut (kontrak server: `eq.E2`).
  static const String openingCode = 'E2';

  /// Pertanyaan lanjutan yang hanya relevan bila pertanyaan induknya dijawab
  /// "Ya" (kunci = lanjutan, nilai = induk). Contoh: lama nyeri (SQ2) tidak
  /// ditanyakan bila pengguna menjawab tidak merasakan nyeri (SQ1).
  ///
  /// Pertanyaan yang dilewati tidak dikirim; server memakai nilai default
  /// ("Tidak" / "< 1 minggu"), sehingga hasil diagnosis sama persis dengan
  /// menjawab "tidak" secara manual (lihat TmdDiagnosisService di backend).
  static const Map<String, String> followUpOf = {
    'SQ2': 'SQ1',
    'SQ3': 'SQ1',
    'SQ4': 'SQ1',
    'SQ6': 'SQ5',
    'SQ7': 'SQ5',
  };

  static const String _yes = 'Ya';

  // State
  DiagnosisState _state = DiagnosisState.initial;
  bool _finished = false;

  List<QuestionModel> _sqQuestions = [];
  List<QuestionModel> _eqQuestions = [];
  List<QuestionModel> _steps = [];
  int _index = 0;
  String _errorMessage = '';

  // Validasi / error input untuk langkah saat ini
  String? _validationError;
  String? _photoError;

  // Pengiriman konsultasi (dimiliki sepenuhnya oleh provider ini)
  SubmissionState _submissionState = SubmissionState.idle;
  String _submissionError = '';
  Consultation? _submissionResult;
  int _generation = 0; // naik setiap reset agar hasil lama diabaikan

  final Map<String, dynamic> _answers = {};

  // --- Getter untuk UI ---
  DiagnosisState get state => _state;
  String get errorMessage => _errorMessage;

  DiagnosisStage get stage {
    if (_finished) return DiagnosisStage.finished;
    return _index < _sqQuestions.length ? DiagnosisStage.sq : DiagnosisStage.eq;
  }

  QuestionModel? get currentQuestion {
    if (_finished || _index < 0 || _index >= _steps.length) return null;
    return _steps[_index];
  }

  /// Nomor langkah saat ini (1-based) dari seluruh langkah SQ + EQ.
  int get stepNumber => _steps.isEmpty ? 0 : _index + 1;
  int get totalSteps => _steps.length;

  /// Kemajuan 0..1 berdasarkan langkah yang sudah dilewati.
  double get progress {
    if (_steps.isEmpty) return 0;
    if (_finished) return 1;
    return _index / _steps.length;
  }

  /// Nomor bagian (1 = pertanyaan gejala, 2 = pemeriksaan mandiri).
  int get sectionNumber => stage == DiagnosisStage.sq ? 1 : 2;
  int get sectionCount => _eqQuestions.isEmpty ? 1 : 2;

  Map<String, dynamic> get answers => _answers;
  List<String> get sqCodes => _sqQuestions.map((q) => q.code).toList();
  List<String> get eqCodes => _eqQuestions.map((q) => q.code).toList();

  String? get validationError => _validationError;
  String? get photoError => _photoError;

  SubmissionState get submissionState => _submissionState;
  String get submissionError => _submissionError;
  Consultation? get submissionResult => _submissionResult;

  /// True bila masih ada langkah sebelumnya untuk dikunjungi kembali.
  bool get canGoBack => !_finished && _previousIndex(_index) != null;

  /// True bila langkah saat ini adalah yang terakhir (tombol menjadi kirim).
  bool get isLastStep => !_finished && _nextIndex(_index) == null;

  /// True bila langkah berikutnya sudah masuk bagian lain (gejala ->
  /// pemeriksaan mandiri) atau tidak ada lagi.
  bool get isLastStepOfSection {
    final next = _nextIndex(_index);
    if (next == null) return true;
    return _index < _sqQuestions.length && next >= _sqQuestions.length;
  }

  /// True bila ada jawaban yang akan hilang jika pengguna keluar.
  bool get hasProgress => _answers.isNotEmpty;

  // --- Memuat pertanyaan ---
  Future<void> fetchQuestions() async {
    if (_steps.isNotEmpty) return; // sudah dimuat
    if (_state == DiagnosisState.loading) return;
    _state = DiagnosisState.loading;
    notifyListeners();
    final generation = _generation;
    try {
      final allQuestions = await _questionRepository.getQuestions();
      if (generation != _generation) return;
      _sqQuestions = allQuestions.sq;
      _eqQuestions = allQuestions.eq;
      _steps = [..._sqQuestions, ..._eqQuestions];
      _index = 0;
      _state = _steps.isEmpty ? DiagnosisState.error : DiagnosisState.loaded;
      _errorMessage = _steps.isEmpty ? 'Pertanyaan tidak ditemukan.' : '';
    } catch (e) {
      if (generation != _generation) return;
      _state = DiagnosisState.error;
      _errorMessage = ApiException.messageOf(e);
    } finally {
      if (generation == _generation) notifyListeners();
    }
  }

  // --- Relevansi pertanyaan (lompati pertanyaan lanjutan) ---
  /// True bila pertanyaan [code] perlu ditanyakan berdasarkan jawaban saat ini.
  bool isApplicable(String code) {
    final parent = followUpOf[code];
    if (parent == null) return true;
    // Bila induknya tidak ada di kuesioner, pertanyaan tetap ditanyakan.
    if (!_steps.any((q) => q.code == parent)) return true;
    return _answers[parent] == _yes;
  }

  int? _nextIndex(int from) {
    for (var i = from + 1; i < _steps.length; i++) {
      if (isApplicable(_steps[i].code)) return i;
    }
    return null;
  }

  int? _previousIndex(int from) {
    for (var i = from - 1; i >= 0; i--) {
      if (isApplicable(_steps[i].code)) return i;
    }
    return null;
  }

  // --- Menjawab ---
  void answerQuestion(String code, dynamic answer) {
    _answers[code] = answer;
    _validationError = null;
    notifyListeners();
  }

  /// Menyimpan skor nyeri satu [area] pada pertanyaan [code] (E1/E4).
  void setAreaScore(String code, String area, int score) {
    final current = _answers[code];
    final updated = <String, int>{};
    if (current is Map) {
      current.forEach((key, value) {
        if (value is num) updated[key.toString()] = value.toInt();
      });
    }
    updated[area] = score;
    answerQuestion(code, updated);
  }

  /// Menyimpan teks bukaan mulut (E2) apa adanya; divalidasi saat lanjut.
  void setOpeningMm(String raw) {
    final updated = _openingAnswer();
    updated['opening_mm'] = raw;
    _answers[openingCode] = updated;
    _validationError = null;
    notifyListeners();
  }

  Map<String, dynamic> _openingAnswer() {
    final current = _answers[openingCode];
    return current is Map
        ? Map<String, dynamic>.from(current)
        : <String, dynamic>{};
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

  /// True bila [question] sudah dijawab lengkap dan valid.
  bool isAnswered(QuestionModel question) => _validate(question) == null;

  /// Pesan validasi untuk langkah saat ini, atau null bila boleh lanjut.
  String? validateCurrentQuestion() {
    final q = currentQuestion;
    return q == null ? null : _validate(q);
  }

  String? _validate(QuestionModel q) {
    final answer = _answers[q.code];
    switch (q.input.type) {
      case 'composite':
        return validateOpeningMm(answer is Map ? answer['opening_mm'] : null);
      case 'group_select_scores':
        final areas = q.input.areas ?? const <String>[];
        final scores = answer is Map ? answer : const {};
        final missing = areas.where((a) => scores[a] is! num).length;
        if (missing == 0) return null;
        return missing == areas.length
            ? 'Beri nilai nyeri untuk setiap area.'
            : 'Masih ada $missing area yang belum dinilai.';
      case 'radio':
      case 'select':
        if (answer == null || answer.toString().isEmpty) {
          return 'Pilih salah satu jawaban untuk melanjutkan.';
        }
        return null;
      default:
        // Tipe yang tidak dikenal tidak menghalangi pengguna.
        return null;
    }
  }

  // --- Navigasi ---
  /// Lanjut ke langkah berikutnya. Mengembalikan false bila jawaban saat ini
  /// belum valid (pesannya ada di [validationError]).
  /// Di langkah terakhir hanya berpindah ke tahap `finished`; pengiriman
  /// dilakukan terpisah lewat [submitConsultation].
  bool nextQuestion() {
    if (_finished) return true;

    final error = validateCurrentQuestion();
    if (error != null) {
      _validationError = error;
      notifyListeners();
      return false;
    }
    _validationError = null;

    final next = _nextIndex(_index);
    if (next == null) {
      _finished = true;
    } else {
      _index = next;
    }
    notifyListeners();
    return true;
  }

  void previousQuestion() {
    if (_finished) return;
    final previous = _previousIndex(_index);
    if (previous == null) return;
    _validationError = null;
    _index = previous;
    notifyListeners();
  }

  // --- Foto bukaan mulut (E2) ---
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
        _deleteQuietly(photoFile);
        _photoError = 'Ukuran foto melebihi 5 MB. Silakan ambil ulang foto dengan resolusi lebih rendah.';
        notifyListeners();
        return;
      }

      final updated = _openingAnswer();
      final previous = updated['photo'];
      if (previous is File && previous.path != photoFile.path) {
        _deleteQuietly(previous);
      }
      updated['photo'] = photoFile; // File dikirim sebagai multipart
      _answers[openingCode] = updated;
      notifyListeners();
    } catch (_) {
      _photoError =
          'Gagal mengambil foto. Pastikan izin kamera telah diberikan.';
      notifyListeners();
    }
  }

  /// Membuang foto yang sudah diambil (foto bersifat opsional).
  void removePhoto() {
    final updated = _openingAnswer();
    final photo = updated.remove('photo');
    if (photo is File) _deleteQuietly(photo);
    _photoError = null;
    if (updated.isEmpty) {
      _answers.remove(openingCode);
    } else {
      _answers[openingCode] = updated;
    }
    notifyListeners();
  }

  /// Foto wajah adalah data kesehatan: file sementara di cache aplikasi
  /// dihapus begitu tidak diperlukan lagi.
  void _deleteCapturedPhoto() {
    final e2 = _answers[openingCode];
    final photo = e2 is Map ? e2['photo'] : null;
    if (photo is File) _deleteQuietly(photo);
  }

  static void _deleteQuietly(File file) {
    file.delete().then<void>((_) {}, onError: (_) {});
  }

  /// Mengosongkan semua jawaban, pertanyaan, dan hasil (pemeriksaan baru/logout).
  void resetDiagnosis() {
    _generation++;
    _deleteCapturedPhoto();
    _state = DiagnosisState.initial;
    _finished = false;
    _index = 0;
    _answers.clear();
    _sqQuestions = [];
    _eqQuestions = [];
    _steps = [];
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

  /// Membangun payload konsultasi dari jawaban saat ini. Pertanyaan lanjutan
  /// yang tidak relevan (lihat [followUpOf]) tidak ikut dikirim, walaupun
  /// sempat dijawab sebelum jawaban induknya diubah.
  ConsultationPayload buildPayload() {
    return ConsultationPayload.fromAnswers(
      answers: _answers,
      sqCodes: sqCodes.where(isApplicable),
      eqCodes: eqCodes.where(isApplicable),
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
      final result = await _consultationRepository.submitConsultation(
        buildPayload(),
      );
      if (generation != _generation) return;
      _submissionResult = result;
      _submissionState = SubmissionState.success;
      _deleteCapturedPhoto();
    } catch (e) {
      if (generation != _generation) return;
      _submissionError = ApiException.messageOf(e);
      _submissionState = SubmissionState.error;
    }
    notifyListeners();
    if (_submissionState == SubmissionState.success) onSubmitted?.call();
  }
}

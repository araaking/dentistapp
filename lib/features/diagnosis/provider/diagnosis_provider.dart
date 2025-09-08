import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/data/repositories/question_repository.dart';
import '../../../core/data/repositories/consultation_repository.dart';
import '../../../core/models/question_model.dart';

enum DiagnosisStage { sq, eq, finished }
enum DiagnosisState { initial, loading, loaded, error }

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

  // Storing answers
  final Map<String, dynamic> _answers = {};

  // Getters for UI
  DiagnosisState get state => _state;
  DiagnosisStage get stage => _stage;
  String get errorMessage => _errorMessage;
  int get currentQuestionNumber => _currentIndex + 1;
  int get totalQuestions {
    final currentList = _getCurrentQuestionList();
    return currentList.length;
  }
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

  // Helper to get the correct question list based on the stage
  List<QuestionModel> _getCurrentQuestionList() {
    return _stage == DiagnosisStage.sq ? _sqQuestions : _eqQuestions;
  }

  Future<void> fetchQuestions() async {
    if (_sqQuestions.isNotEmpty) return; // Prevent re-fetching
    _state = DiagnosisState.loading;
    notifyListeners();
    try {
      final allQuestions = await _questionRepository.getQuestions();
      // Now allQuestions is AllQuestionsModel, not List<QuestionModel>
      // Use allQuestions.sq and allQuestions.eq as needed
      // For example:
      _sqQuestions = allQuestions.sq;
      _eqQuestions = allQuestions.eq;
      _state = _sqQuestions.isEmpty ? DiagnosisState.error : DiagnosisState.loaded;
      _errorMessage = _sqQuestions.isEmpty ? "No questions found." : '';
    } catch (e) {
      _state = DiagnosisState.error;
      _errorMessage = "Failed to load questions: $e";
    } finally {
      notifyListeners();
    }
  }
  
  void answerQuestion(String code, dynamic answer) {
    _answers[code] = answer;
    print("Answered $code with: $answer");
    notifyListeners();
  }
  
  // Compatibility with existing UI
  void answerQuestionAndProceed(String questionCode, String answer) {
    answerQuestion(questionCode, answer);
    nextQuestion();
  }
  
  void nextQuestion() {
    final currentList = _getCurrentQuestionList();
    if (_currentIndex < currentList.length - 1) {
      _currentIndex++;
    } else {
      // Transition from SQ to EQ, or finish
      if (_stage == DiagnosisStage.sq) {
        _stage = DiagnosisStage.eq;
        _currentIndex = 0;
      } else {
        _stage = DiagnosisStage.finished;
        // Submit answers to repository
        _submitConsultation();
      }
    }
    notifyListeners();
  }

  void previousQuestion() {
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
  
  // Alias for UI using old method name
  void goToPreviousQuestion() => previousQuestion();

  // Selected answer for current (used by SQ radio)
  String? getSelectedAnswerForCurrentQuestion() {
    final q = currentQuestion;
    if (q == null) return null;
    final value = _answers[q.code];
    return value is String ? value : null;
  }

  // --- EQ Specific Methods ---
  Future<void> takePictureForEQ2() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        final File photoFile = File(photo.path);
        // Store the file path in answers dengan struktur yang benar
        final currentAnswers = (_answers['E2'] as Map<String, dynamic>?) ?? {};
        final newAnswers = Map<String, dynamic>.from(currentAnswers);
        newAnswers['photo'] = photoFile;  // Store File object for upload
        answerQuestion('E2', newAnswers);
      }
    } catch (e) {
      print("Error taking picture: $e");
      // Handle camera error
    }
  }

  void resetDiagnosis() {
    _state = DiagnosisState.initial;
    _stage = DiagnosisStage.sq;
    _currentIndex = 0;
    _answers.clear();
    _sqQuestions.clear();
    _eqQuestions.clear();
    _errorMessage = '';
    notifyListeners();
  }

  Future<void> _submitConsultation() async {
    try {
      // Extract E2 photo file jika ada
      File? e2PhotoFile;
      final e2Data = _answers['E2'] as Map<String, dynamic>?;
      if (e2Data != null && e2Data.containsKey('photo')) {
        e2PhotoFile = e2Data['photo'] as File;
      }

      // Separate SQ and EQ answers
      final sqAnswers = Map<String, dynamic>.fromEntries(
        _answers.entries.where((entry) => entry.key.startsWith('SQ'))
      );
      final eqAnswers = Map<String, dynamic>.fromEntries(
        _answers.entries.where((entry) => entry.key.startsWith('E'))
      );

      // Panggil repository
      await _consultationRepository.submitConsultation(
        sqAnswers: sqAnswers,
        eqAnswers: eqAnswers,
        e2Photo: e2PhotoFile,
      );
      
      print("Consultation submitted successfully!");
    } catch (e) {
      print("Error submitting consultation: $e");
      // You might want to show an error dialog or handle this differently
    }
  }
}

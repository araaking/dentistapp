import 'dart:async';

import 'package:dentistapp/core/data/consultation_payload.dart';
import 'package:dentistapp/core/data/repositories/consultation_repository.dart';
import 'package:dentistapp/core/data/repositories/question_repository.dart';
import 'package:dentistapp/core/errors/exceptions.dart';
import 'package:dentistapp/core/models/question_model.dart';
import 'package:dentistapp/features/diagnosis/provider/diagnosis_provider.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeQuestionRepository implements QuestionRepository {
  int calls = 0;

  @override
  Future<AllQuestionsModel> getQuestions() async {
    calls++;
    return AllQuestionsModel.fromJson(_questionsJson);
  }
}

class FakeConsultationRepository implements ConsultationRepository {
  int submitCalls = 0;
  ConsultationPayload? lastPayload;

  /// Bila diisi, submit menunggu completer ini.
  Completer<Map<String, dynamic>>? completer;

  /// Bila diisi, submit pertama melempar error ini.
  ApiException? failFirstWith;

  @override
  Future<Map<String, dynamic>> submitConsultation(
      ConsultationPayload payload) {
    submitCalls++;
    lastPayload = payload;
    if (failFirstWith != null && submitCalls == 1) {
      return Future<Map<String, dynamic>>.error(failFirstWith!);
    }
    final c = completer;
    if (c != null) return c.future;
    return Future.value({
      'consultation_id': submitCalls,
      'diagnoses': ['Myalgia'],
    });
  }

  @override
  Future<List<dynamic>> getConsultationHistory() async => [];

  @override
  Future<List<dynamic>> getConsultations() async => [];

  @override
  Future<Map<String, dynamic>> getConsultationDetail(int consultationId) async =>
      {};
}

final Map<String, dynamic> _questionsJson = {
  'sq': [
    {
      'code': 'SQ1',
      'text': 'Nyeri?',
      'input': {
        'type': 'radio',
        'options': ['Ya', 'Tidak'],
        'default': 'Tidak',
      },
    },
    {
      'code': 'SQ8',
      'text': 'Bunyi?',
      'input': {
        'type': 'select',
        'options': ['Tidak ada', 'Sesekali', 'Sering'],
        'default': 'Tidak ada',
      },
    },
  ],
  'eq': [
    {
      'code': 'E1',
      'text': 'Nyeri palpasi',
      'input': {
        'type': 'group_select_scores',
        'areas': ['Temporalis', 'Masseter', 'TMJ'],
        'min': 0,
        'max': 3,
        'labels': ['0 - Tidak Nyeri', '1 - Ringan', '2 - Sedang', '3 - Berat'],
      },
    },
    {
      'code': 'E2',
      'text': 'Bukaan mulut',
      'input': {'type': 'composite'},
    },
    {
      'code': 'E3',
      'text': 'Bunyi sendi',
      'input': {
        'type': 'radio',
        'options': [
          {'value': 'Tidak ada', 'label': 'Tidak ada'},
          {'value': 'Kliking', 'label': 'Kliking', 'audio': 'x'},
        ],
        'default': 'Tidak ada',
      },
    },
    {
      'code': 'E4',
      'text': 'Nyeri',
      'input': {
        'type': 'group_select_scores',
        'areas': ['Temporalis', 'Masseter', 'TMJ'],
        'min': 0,
        'max': 3,
      },
    },
  ],
};

/// Maju sampai tahap finished; mengisi bukaan mulut valid bila diminta.
void walkToEnd(DiagnosisProvider provider) {
  var guard = 0;
  while (provider.stage != DiagnosisStage.finished && guard++ < 50) {
    if (!provider.nextQuestion()) {
      provider.setOpeningMm('40');
    }
  }
}

void main() {
  late FakeQuestionRepository questions;
  late FakeConsultationRepository consultations;
  late DiagnosisProvider provider;

  setUp(() async {
    questions = FakeQuestionRepository();
    consultations = FakeConsultationRepository();
    provider = DiagnosisProvider(questions, consultations);
    await provider.fetchQuestions();
  });

  group('jawaban default', () {
    test('terisi dari input.default saat pertanyaan dimuat', () {
      expect(provider.state, DiagnosisState.loaded);
      expect(provider.answers['SQ1'], 'Tidak');
      expect(provider.answers['SQ8'], 'Tidak ada');
      expect(provider.answers['E3'], 'Tidak ada');
      expect(provider.answers['E1'],
          {'Temporalis': 0, 'Masseter': 0, 'TMJ': 0});
      expect(provider.answers['E4'],
          {'Temporalis': 0, 'Masseter': 0, 'TMJ': 0});
      expect(provider.answers.containsKey('E2'), isFalse);
    });
  });

  group('validasi E2', () {
    test('wajib angka 0-100 sebelum lanjut', () {
      // SQ1 -> SQ8 -> E1 -> E2
      for (var i = 0; i < 3; i++) {
        expect(provider.nextQuestion(), isTrue);
      }
      expect(provider.currentQuestion!.code, 'E2');

      expect(provider.nextQuestion(), isFalse);
      expect(provider.validationError, isNotNull);

      provider.setOpeningMm('abc');
      expect(provider.nextQuestion(), isFalse);

      provider.setOpeningMm('101');
      expect(provider.nextQuestion(), isFalse);
      expect(provider.validationError, 'Bukaan mulut harus antara 0 dan 100 mm.');

      provider.setOpeningMm('40');
      expect(provider.nextQuestion(), isTrue);
      expect(provider.validationError, isNull);
      expect(provider.currentQuestion!.code, 'E3');
    });
  });

  group('pengiriman konsultasi', () {
    test('nextQuestion di akhir hanya berpindah ke finished, tidak mengirim', () {
      walkToEnd(provider);
      expect(provider.stage, DiagnosisStage.finished);
      expect(consultations.submitCalls, 0);
      expect(provider.submissionState, SubmissionState.idle);
    });

    test('payload: E2 hanya opening_mm dan jawaban lengkap', () {
      walkToEnd(provider);
      final payload = provider.buildPayload();

      expect(payload.sq, {'SQ1': 'Tidak', 'SQ8': 'Tidak ada'});
      expect(payload.eq['E2'], {'opening_mm': 40});
      expect(payload.eq['E3'], 'Tidak ada');
      expect(payload.eq['E1'], {'Temporalis': 0, 'Masseter': 0, 'TMJ': 0});
      expect(payload.photo, isNull);
    });

    test('guard: dua pemanggilan bersamaan hanya mengirim satu kali', () async {
      walkToEnd(provider);
      consultations.completer = Completer<Map<String, dynamic>>();

      final first = provider.submitConsultation();
      final second = provider.submitConsultation();
      expect(provider.submissionState, SubmissionState.submitting);

      consultations.completer!.complete({
        'consultation_id': 12,
        'diagnoses': ['Myalgia'],
      });
      await Future.wait([first, second]);

      expect(consultations.submitCalls, 1);
      expect(provider.submissionState, SubmissionState.success);
      expect(provider.submissionResult!['consultation_id'], 12);
    });

    test('guard: setelah sukses pemanggilan berikutnya diabaikan', () async {
      walkToEnd(provider);
      await provider.submitConsultation();
      await provider.submitConsultation();
      expect(consultations.submitCalls, 1);
      expect(provider.submissionState, SubmissionState.success);
    });

    test('setelah gagal boleh dicoba lagi dan pesan error tanpa prefix', () async {
      walkToEnd(provider);
      consultations.failFirstWith = NetworkException();

      await provider.submitConsultation();
      expect(provider.submissionState, SubmissionState.error);
      expect(provider.submissionError,
          'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.');

      await provider.submitConsultation();
      expect(consultations.submitCalls, 2);
      expect(provider.submissionState, SubmissionState.success);
    });

    test('resetDiagnosis mengosongkan hasil dan mengabaikan respons lama', () async {
      walkToEnd(provider);
      consultations.completer = Completer<Map<String, dynamic>>();
      final pending = provider.submitConsultation();

      provider.resetDiagnosis();
      consultations.completer!.complete({'consultation_id': 1});
      await pending;

      expect(provider.submissionState, SubmissionState.idle);
      expect(provider.submissionResult, isNull);
      expect(provider.answers, isEmpty);
    });
  });
}

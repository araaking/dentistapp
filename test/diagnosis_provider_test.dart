import 'dart:async';

import 'package:dentistapp/core/data/consultation_payload.dart';
import 'package:dentistapp/core/data/repositories/consultation_repository.dart';
import 'package:dentistapp/core/data/repositories/question_repository.dart';
import 'package:dentistapp/core/errors/exceptions.dart';
import 'package:dentistapp/core/models/consultation.dart';
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
  Completer<Consultation>? completer;

  /// Bila diisi, submit pertama melempar error ini.
  ApiException? failFirstWith;

  @override
  Future<Consultation> submitConsultation(ConsultationPayload payload) {
    submitCalls++;
    lastPayload = payload;
    if (failFirstWith != null && submitCalls == 1) {
      return Future<Consultation>.error(failFirstWith!);
    }
    final c = completer;
    if (c != null) return c.future;
    return Future.value(
      Consultation(id: submitCalls, diagnoses: const ['Myalgia']),
    );
  }

  @override
  Future<List<Consultation>> getConsultationHistory() async => [];
}

Map<String, dynamic> _yesNo(String code, String text) => {
  'code': code,
  'text': text,
  'input': {
    'type': 'radio',
    'options': ['Ya', 'Tidak'],
    'default': 'Tidak',
  },
};

final Map<String, dynamic> _questionsJson = {
  'sq': [
    _yesNo('SQ1', 'Nyeri?'),
    {
      'code': 'SQ2',
      'text': 'Berapa lama?',
      'input': {
        'type': 'radio',
        'options': ['< 1 minggu', '>= 1 minggu'],
        'default': '< 1 minggu',
      },
    },
    _yesNo('SQ3', 'Kambuhan?'),
    _yesNo('SQ4', 'Dipengaruhi aktivitas?'),
    _yesNo('SQ5', 'Sakit kepala?'),
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

/// Menjawab pertanyaan saat ini dengan jawaban "tidak ada keluhan" yang valid.
void answerCurrent(DiagnosisProvider provider, {String yesNo = 'Tidak'}) {
  final q = provider.currentQuestion!;
  switch (q.input.type) {
    case 'group_select_scores':
      for (final area in q.input.areas!) {
        provider.setAreaScore(q.code, area, 0);
      }
    case 'composite':
      provider.setOpeningMm('40');
    default:
      final first = q.input.options!.first;
      final options = q.input.options!
          .map((o) => o is Map ? o['value'].toString() : o.toString())
          .toList();
      provider.answerQuestion(
        q.code,
        options.contains(yesNo)
            ? yesNo
            : (first is Map ? first['value'] : first),
      );
  }
}

/// Menjawab semua langkah sampai tahap finished.
void walkToEnd(DiagnosisProvider provider, {String yesNo = 'Tidak'}) {
  var guard = 0;
  while (provider.stage != DiagnosisStage.finished && guard++ < 50) {
    answerCurrent(provider, yesNo: yesNo);
    expect(provider.nextQuestion(), isTrue);
  }
}

/// Maju sampai pertanyaan [code] tampil.
void walkTo(DiagnosisProvider provider, String code) {
  var guard = 0;
  while (provider.currentQuestion?.code != code && guard++ < 50) {
    answerCurrent(provider);
    expect(provider.nextQuestion(), isTrue);
  }
  expect(provider.currentQuestion!.code, code);
}

void main() {
  late FakeQuestionRepository questions;
  late FakeConsultationRepository consultations;
  late DiagnosisProvider provider;
  late int submittedCalls;

  setUp(() async {
    questions = FakeQuestionRepository();
    consultations = FakeConsultationRepository();
    submittedCalls = 0;
    provider = DiagnosisProvider(
      questions,
      consultations,
      onSubmitted: () => submittedCalls++,
    );
    await provider.fetchQuestions();
  });

  group('jawaban wajib diisi pengguna', () {
    test('tidak ada jawaban yang terisi otomatis dari input.default', () {
      expect(provider.state, DiagnosisState.loaded);
      expect(provider.answers, isEmpty);
      expect(provider.hasProgress, isFalse);
    });

    test('pilihan tunggal: tidak bisa lanjut sebelum memilih', () {
      expect(provider.nextQuestion(), isFalse);
      expect(
        provider.validationError,
        'Pilih salah satu jawaban untuk melanjutkan.',
      );
      expect(provider.currentQuestion!.code, 'SQ1');

      provider.answerQuestion('SQ1', 'Tidak');
      expect(provider.validationError, isNull);
      expect(provider.nextQuestion(), isTrue);
    });

    test('skor nyeri: semua area harus dinilai', () {
      walkTo(provider, 'E1');

      expect(provider.nextQuestion(), isFalse);
      expect(provider.validationError, 'Beri nilai nyeri untuk setiap area.');

      provider.setAreaScore('E1', 'Temporalis', 2);
      expect(provider.nextQuestion(), isFalse);
      expect(provider.validationError, 'Masih ada 2 area yang belum dinilai.');

      provider.setAreaScore('E1', 'Masseter', 0);
      provider.setAreaScore('E1', 'TMJ', 1);
      expect(provider.answers['E1'], {
        'Temporalis': 2,
        'Masseter': 0,
        'TMJ': 1,
      });
      expect(provider.nextQuestion(), isTrue);
    });
  });

  group('pertanyaan lanjutan', () {
    test('SQ1 = Tidak melewati SQ2-SQ4', () {
      provider.answerQuestion('SQ1', 'Tidak');
      expect(provider.nextQuestion(), isTrue);
      expect(provider.currentQuestion!.code, 'SQ5');

      provider.previousQuestion();
      expect(provider.currentQuestion!.code, 'SQ1');
    });

    test('SQ1 = Ya menanyakan SQ2-SQ4', () {
      provider.answerQuestion('SQ1', 'Ya');
      expect(provider.nextQuestion(), isTrue);
      expect(provider.currentQuestion!.code, 'SQ2');
    });

    test('jawaban lanjutan dibuang dari payload bila induknya diubah', () {
      provider.answerQuestion('SQ1', 'Ya');
      provider.nextQuestion();
      provider.answerQuestion('SQ2', '>= 1 minggu');
      provider.previousQuestion();
      provider.answerQuestion('SQ1', 'Tidak');

      walkToEnd(provider);
      final payload = provider.buildPayload();
      expect(payload.sq.containsKey('SQ2'), isFalse);
      expect(payload.sq['SQ1'], 'Tidak');
    });

    test('nomor langkah dan kemajuan mengikuti seluruh langkah SQ + EQ', () {
      expect(provider.totalSteps, 10);
      expect(provider.stepNumber, 1);
      expect(provider.sectionNumber, 1);
      expect(provider.canGoBack, isFalse);

      walkTo(provider, 'E1');
      expect(provider.stage, DiagnosisStage.eq);
      expect(provider.sectionNumber, 2);
      expect(provider.stepNumber, 7);
      expect(provider.canGoBack, isTrue);

      walkTo(provider, 'E4');
      expect(provider.isLastStep, isTrue);
    });
  });

  group('validasi E2', () {
    test('wajib angka 0-100 sebelum lanjut', () {
      walkTo(provider, 'E2');

      expect(provider.nextQuestion(), isFalse);
      expect(provider.validationError, isNotNull);

      provider.setOpeningMm('abc');
      expect(provider.nextQuestion(), isFalse);

      provider.setOpeningMm('101');
      expect(provider.nextQuestion(), isFalse);
      expect(
        provider.validationError,
        'Bukaan mulut harus antara 0 dan 100 mm.',
      );

      provider.setOpeningMm('40');
      expect(provider.nextQuestion(), isTrue);
      expect(provider.validationError, isNull);
      expect(provider.currentQuestion!.code, 'E3');
    });
  });

  group('pengiriman konsultasi', () {
    test(
      'nextQuestion di akhir hanya berpindah ke finished, tidak mengirim',
      () {
        walkToEnd(provider);
        expect(provider.stage, DiagnosisStage.finished);
        expect(provider.progress, 1);
        expect(consultations.submitCalls, 0);
        expect(provider.submissionState, SubmissionState.idle);
      },
    );

    test('payload: hanya pertanyaan yang ditanyakan, E2 hanya opening_mm', () {
      walkToEnd(provider);
      final payload = provider.buildPayload();

      expect(payload.sq, {'SQ1': 'Tidak', 'SQ5': 'Tidak', 'SQ8': 'Tidak ada'});
      expect(payload.eq['E2'], {'opening_mm': 40});
      expect(payload.eq['E3'], 'Tidak ada');
      expect(payload.eq['E1'], {'Temporalis': 0, 'Masseter': 0, 'TMJ': 0});
      expect(payload.photo, isNull);
    });

    test('payload lengkap bila semua pertanyaan lanjutan ditanyakan', () {
      walkToEnd(provider, yesNo: 'Ya');
      expect(provider.buildPayload().sq.keys, [
        'SQ1',
        'SQ2',
        'SQ3',
        'SQ4',
        'SQ5',
        'SQ8',
      ]);
    });

    test('guard: dua pemanggilan bersamaan hanya mengirim satu kali', () async {
      walkToEnd(provider);
      consultations.completer = Completer<Consultation>();

      final first = provider.submitConsultation();
      final second = provider.submitConsultation();
      expect(provider.submissionState, SubmissionState.submitting);

      consultations.completer!.complete(
        const Consultation(id: 12, diagnoses: ['Myalgia']),
      );
      await Future.wait([first, second]);

      expect(consultations.submitCalls, 1);
      expect(provider.submissionState, SubmissionState.success);
      expect(provider.submissionResult!.id, 12);
      expect(submittedCalls, 1);
    });

    test('guard: setelah sukses pemanggilan berikutnya diabaikan', () async {
      walkToEnd(provider);
      await provider.submitConsultation();
      await provider.submitConsultation();
      expect(consultations.submitCalls, 1);
      expect(provider.submissionState, SubmissionState.success);
      expect(submittedCalls, 1);
    });

    test(
      'setelah gagal boleh dicoba lagi dan pesan error tanpa prefix',
      () async {
        walkToEnd(provider);
        consultations.failFirstWith = NetworkException();

        await provider.submitConsultation();
        expect(provider.submissionState, SubmissionState.error);
        expect(
          provider.submissionError,
          'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
        );
        expect(submittedCalls, 0);

        await provider.submitConsultation();
        expect(consultations.submitCalls, 2);
        expect(provider.submissionState, SubmissionState.success);
      },
    );

    test(
      'resetDiagnosis mengosongkan hasil dan mengabaikan respons lama',
      () async {
        walkToEnd(provider);
        consultations.completer = Completer<Consultation>();
        final pending = provider.submitConsultation();

        provider.resetDiagnosis();
        consultations.completer!.complete(const Consultation(id: 1));
        await pending;

        expect(provider.submissionState, SubmissionState.idle);
        expect(provider.submissionResult, isNull);
        expect(provider.answers, isEmpty);
        expect(submittedCalls, 0);
      },
    );
  });
}

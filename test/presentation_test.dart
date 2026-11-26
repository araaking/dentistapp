import 'package:dentistapp/core/models/consultation.dart';
import 'package:dentistapp/core/models/patient.dart';
import 'package:dentistapp/core/models/question_model.dart';
import 'package:dentistapp/core/utils/date_format.dart';
import 'package:dentistapp/core/utils/diagnosis_info.dart';
import 'package:dentistapp/features/diagnosis/question_presenter.dart';
import 'package:dentistapp/features/profile/widgets/profile_form.dart';
import 'package:flutter_test/flutter_test.dart';

QuestionModel _question(String code, String text) => QuestionModel(
  code: code,
  text: text,
  input: InputModel(type: 'radio'),
);

void main() {
  group('QuestionPresenter', () {
    test('membuang petunjuk format jawaban dari teks pertanyaan', () {
      expect(
        QuestionPresenter.title(
          _question(
            'SQ2',
            'Berapa lama nyeri berlangsung? (Jawaban: < 1 minggu atau >= 1 minggu)',
          ),
        ),
        'Berapa lama nyeri berlangsung?',
      );
      expect(
        QuestionPresenter.title(
          _question(
            'SQ4',
            'Apakah aktivitas (mengunyah, membuka mulut lebar) memengaruhi rasa sakit?',
          ),
        ),
        'Apakah aktivitas (mengunyah, membuka mulut lebar) memengaruhi rasa sakit?',
      );
    });

    test('label opsi ramah pengguna tanpa mengubah nilainya', () {
      expect(
        QuestionPresenter.optionLabel('SQ2', '< 1 minggu'),
        'Kurang dari 1 minggu',
      );
      expect(
        QuestionPresenter.optionLabel('SQ2', '>= 1 minggu'),
        '1 minggu atau lebih',
      );
      expect(
        QuestionPresenter.optionLabel('SQ6', '>= 1x/minggu'),
        '1x/minggu atau lebih',
      );
      expect(QuestionPresenter.optionLabel('SQ1', 'Ya'), 'Ya');
      // SQ3: opsi dari server sudah deskriptif, ditampilkan apa adanya.
      expect(
        QuestionPresenter.optionLabel('SQ3', 'Persisten (terus-menerus)'),
        'Persisten (terus-menerus)',
      );
      expect(
        QuestionPresenter.optionLabel('SQ3', 'Kambuhan (hilang timbul)'),
        'Kambuhan (hilang timbul)',
      );
    });

    test('label skor ringkas dan nama area', () {
      expect(QuestionPresenter.shortScoreLabel('0 - Tidak Nyeri'), 'Tidak');
      expect(QuestionPresenter.shortScoreLabel('2 - Nyeri Sedang'), 'Sedang');
      expect(QuestionPresenter.shortScoreLabel(null), '');
      expect(QuestionPresenter.areaLabel('TMJ'), 'Sendi rahang');
      expect(QuestionPresenter.areaLabel('Lainnya'), 'Lainnya');
    });
  });

  group('Consultation.fromJson', () {
    test('bentuk daftar riwayat (diagnoses berupa objek)', () {
      final c = Consultation.fromJson({
        'id': 12,
        'consultation_date': '2026-01-10T08:30:00.000000Z',
        'diagnoses': [
          {'id': 20, 'name': 'Myalgia'},
        ],
        'e2_photo_url': 'https://evil.example/api/consultations/12/photo',
      });
      expect(c.id, 12);
      expect(c.date, isNotNull);
      expect(c.diagnoses, ['Myalgia']);
      // URL foto selalu diarahkan ke host API, bukan host dari respons.
      expect(
        c.photoUrl,
        'https://dentist.croloze.com/api/consultations/12/photo',
      );
    });

    test('beberapa diagnosis dipertahankan urutannya di kedua bentuk', () {
      final fromStrings = Consultation.fromJson({
        'consultation_id': 1,
        'diagnoses': ['Myalgia', 'Arthralgia', 'Subluxation'],
      });
      expect(fromStrings.diagnoses, ['Myalgia', 'Arthralgia', 'Subluxation']);
      expect(fromStrings.primaryDiagnosis, 'Myalgia');

      final fromObjects = Consultation.fromJson({
        'id': 2,
        'diagnoses': [
          {'id': 1, 'name': 'Degenerative joint disease'},
          {'id': 2, 'name': 'Other Disc-based TMD'},
          {'id': 3, 'name': 'Acute closed lock'},
        ],
      });
      expect(fromObjects.diagnoses, [
        'Degenerative joint disease',
        'Other Disc-based TMD',
        'Acute closed lock',
      ]);
    });

    test('bentuk hasil kirim (diagnoses berupa string) dan data rusak', () {
      final c = Consultation.fromJson({
        'consultation_id': '7',
        'diagnoses': ['Arthralgia', null, ''],
        'e2_photo_url': null,
      });
      expect(c.id, 7);
      expect(c.primaryDiagnosis, 'Arthralgia');
      expect(c.photoUrl, isNull);

      final broken = Consultation.fromJson({'diagnoses': 'x', 'id': {}});
      expect(broken.id, isNull);
      expect(broken.diagnoses, isEmpty);
      expect(broken.date, isNull);
    });
  });

  group('DiagnosisInfo', () {
    test('nama dari server diterjemahkan dan nadanya benar', () {
      expect(DiagnosisInfo.of('Myalgia').title, 'Nyeri otot rahang');
      expect(DiagnosisInfo.of('Myalgia').tone, DiagnosisTone.attention);
      expect(
        DiagnosisInfo.of(DiagnosisInfo.noneName).tone,
        DiagnosisTone.clear,
      );
      expect(DiagnosisInfo.of(null).tone, DiagnosisTone.clear);
    });

    test('semua nama yang bisa dikirim server punya penjelasan', () {
      const names = [
        'Myalgia',
        'Arthralgia',
        'Headache attributed to TMD (HA-TMD)',
        'Degenerative joint disease',
        'Acute closed lock',
        'Other Disc-based TMD',
        'Subluxation',
        'Joint-related TMD', // nama lama, masih ada di riwayat
        DiagnosisInfo.noneName,
      ];
      for (final name in names) {
        final info = DiagnosisInfo.of(name);
        expect(
          info.description,
          isNot('Penjelasan untuk hasil ini belum tersedia.'),
          reason: name,
        );
        expect(info.title, isNot(name), reason: name);
        expect(
          info.tone,
          name == DiagnosisInfo.noneName
              ? DiagnosisTone.clear
              : DiagnosisTone.attention,
          reason: name,
        );
      }
    });

    test('nama yang tidak dikenal ditampilkan apa adanya', () {
      final info = DiagnosisInfo.of('Diagnosis Baru');
      expect(info.title, 'Diagnosis Baru');
      expect(info.tone, DiagnosisTone.attention);
    });
  });

  group('Patient', () {
    test('parsing, inisial, dan label', () {
      final p = Patient.fromJson({
        'name': '  Alfian Dimas Putra ',
        'date_of_birth': '2000-08-11',
        'gender': 'Male',
        'phone_number': '',
      });
      expect(p.name, 'Alfian Dimas Putra');
      expect(p.firstName, 'Alfian');
      expect(p.initials, 'AP');
      expect(p.genderLabel, 'Laki-laki');
      expect(p.phoneNumber, isNull);
      expect(formatCalendarDateId(p.dateOfBirth), '11 Agustus 2000');
      expect(toApiDate(p.dateOfBirth!), '2000-08-11');
    });

    test('nama kosong tidak membuat aplikasi gagal', () {
      final p = Patient.fromJson({'name': null});
      expect(p.initials, '?');
      expect(p.firstName, '');
      expect(p.genderLabel, '-');
    });
  });

  group('validasi form profil', () {
    test('nomor telepon opsional tetapi harus wajar bila diisi', () {
      expect(ProfileForm.validatePhone(''), isNull);
      expect(ProfileForm.validatePhone('081324716701'), isNull);
      expect(ProfileForm.validatePhone('+6281324716701'), isNull);
      expect(ProfileForm.validatePhone('12345'), isNotNull);
      expect(ProfileForm.validatePhone('abcdefghij'), isNotNull);
    });

    test('nama wajib', () {
      expect(ProfileForm.validateName('  '), isNotNull);
      expect(ProfileForm.validateName('Budi'), isNull);
    });
  });
}

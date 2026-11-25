import 'dart:io';

import 'package:dentistapp/core/data/consultation_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sqCodes = ['SQ1', 'SQ2'];
  const eqCodes = ['E1', 'E2', 'E3', 'E4'];

  Map<String, dynamic> sampleAnswers({Object? openingMm = '42'}) => {
        'SQ1': 'Ya',
        'SQ2': '>= 1 minggu',
        'E1': <String, int>{'Temporalis': 1, 'Masseter': 0, 'TMJ': 0},
        'E2': <String, dynamic>{
          'opening_mm': openingMm,
          'photo': File('/tmp/mulut.jpg'),
        },
        'E3': 'Tidak ada',
        'E4': <String, int>{'Temporalis': 0, 'Masseter': 2, 'TMJ': 3},
      };

  group('ConsultationPayload.fromAnswers', () {
    test('memisahkan SQ, EQ, dan foto', () {
      final payload = ConsultationPayload.fromAnswers(
        answers: sampleAnswers(),
        sqCodes: sqCodes,
        eqCodes: eqCodes,
      );

      expect(payload.sq, {'SQ1': 'Ya', 'SQ2': '>= 1 minggu'});
      expect(payload.eq['E1'], {'Temporalis': 1, 'Masseter': 0, 'TMJ': 0});
      expect(payload.eq['E3'], 'Tidak ada');
      expect(payload.eq['E4'], {'Temporalis': 0, 'Masseter': 2, 'TMJ': 3});
      expect(payload.photo, isNotNull);
      expect(payload.photo!.path, '/tmp/mulut.jpg');
    });

    test('E2 hanya berisi opening_mm sebagai angka (tanpa File)', () {
      final payload = ConsultationPayload.fromAnswers(
        answers: sampleAnswers(),
        sqCodes: sqCodes,
        eqCodes: eqCodes,
      );

      expect(payload.eq['E2'], {'opening_mm': 42});
      expect(payload.eq['E2']['opening_mm'], isA<int>());

      bool containsFile(dynamic v) {
        if (v is File) return true;
        if (v is Map) return v.values.any(containsFile);
        return false;
      }

      expect(payload.eq.values.any(containsFile), isFalse);
    });

    test('opening_mm desimal tetap angka', () {
      final payload = ConsultationPayload.fromAnswers(
        answers: sampleAnswers(openingMm: '42,5'),
        sqCodes: sqCodes,
        eqCodes: eqCodes,
      );
      expect(payload.eq['E2'], {'opening_mm': 42.5});
    });

    test('opening_mm tidak valid tidak dikirim', () {
      final payload = ConsultationPayload.fromAnswers(
        answers: sampleAnswers(openingMm: 'abc'),
        sqCodes: sqCodes,
        eqCodes: eqCodes,
      );
      expect(payload.eq.containsKey('E2'), isFalse);
    });

    test('kode di luar daftar pertanyaan diabaikan', () {
      final payload = ConsultationPayload.fromAnswers(
        answers: {...sampleAnswers(), 'SQ99': 'Ya', 'E9': 'x'},
        sqCodes: sqCodes,
        eqCodes: eqCodes,
      );
      expect(payload.sq.containsKey('SQ99'), isFalse);
      expect(payload.eq.containsKey('E9'), isFalse);
    });
  });

  group('toFormFields / flatten', () {
    test('menghasilkan notasi kurung tanpa File', () {
      final fields = ConsultationPayload.fromAnswers(
        answers: sampleAnswers(),
        sqCodes: sqCodes,
        eqCodes: eqCodes,
      ).toFormFields();

      expect(fields['sq[SQ1]'], 'Ya');
      expect(fields['sq[SQ2]'], '>= 1 minggu');
      expect(fields['eq[E1][Temporalis]'], 1);
      expect(fields['eq[E1][TMJ]'], 0);
      expect(fields['eq[E2][opening_mm]'], 42);
      expect(fields['eq[E3]'], 'Tidak ada');
      expect(fields['eq[E4][TMJ]'], 3);
      expect(fields.keys.any((k) => k.contains('photo')), isFalse);
      expect(fields.values.any((v) => v is File), isFalse);
    });
  });

  group('foto', () {
    test('content type mengikuti ekstensi', () {
      expect(ConsultationPayload.photoContentType('a.jpg').mimeType,
          'image/jpeg');
      expect(ConsultationPayload.photoContentType('a.JPEG').mimeType,
          'image/jpeg');
      expect(
          ConsultationPayload.photoContentType('a.png').mimeType, 'image/png');
      expect(
          ConsultationPayload.photoContentType('A.PNG').mimeType, 'image/png');
    });

    test('nama file dari path', () {
      expect(ConsultationPayload.fileNameOf('/data/user/0/cache/mulut.jpg'),
          'mulut.jpg');
      expect(ConsultationPayload.fileNameOf(r'C:\tmp\mulut.png'), 'mulut.png');
      expect(ConsultationPayload.fileNameOf('mulut.png'), 'mulut.png');
    });
  });

  group('parseOpeningMm', () {
    test('menerima angka dan teks angka', () {
      expect(ConsultationPayload.parseOpeningMm(40), 40);
      expect(ConsultationPayload.parseOpeningMm(' 40 '), 40);
      expect(ConsultationPayload.parseOpeningMm('40.0'), 40);
      expect(ConsultationPayload.parseOpeningMm('35,5'), 35.5);
    });

    test('menolak selain angka biasa', () {
      expect(ConsultationPayload.parseOpeningMm(''), isNull);
      expect(ConsultationPayload.parseOpeningMm(null), isNull);
      expect(ConsultationPayload.parseOpeningMm('abc'), isNull);
      expect(ConsultationPayload.parseOpeningMm('0x10'), isNull);
      expect(ConsultationPayload.parseOpeningMm('1e2'), isNull);
      expect(ConsultationPayload.parseOpeningMm('-5'), isNull);
    });
  });
}

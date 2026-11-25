import 'dart:io';

import 'package:http_parser/http_parser.dart';

/// Data konsultasi yang siap dikirim ke `POST api/consultations`.
///
/// Dibangun sekali dari jawaban pengguna:
/// - [sq]: `{SQ1: 'Ya', ...}`
/// - [eq]: `E1`/`E4` = `{area: skor}`, `E2` = `{opening_mm: angka}` (tanpa
///   File), `E3` = string.
/// - [photo]: file foto E2 (dikirim terpisah sebagai `e2_photo_file`).
class ConsultationPayload {
  final Map<String, dynamic> sq;
  final Map<String, dynamic> eq;
  final File? photo;

  const ConsultationPayload({
    required this.sq,
    required this.eq,
    this.photo,
  });

  /// Membangun payload dari map jawaban milik DiagnosisProvider.
  ///
  /// Jawaban E2 berbentuk `{'opening_mm': <String|num>, 'photo': File}`;
  /// File dipisahkan ke [photo] dan tidak pernah masuk ke [eq].
  factory ConsultationPayload.fromAnswers({
    required Map<String, dynamic> answers,
    required Iterable<String> sqCodes,
    required Iterable<String> eqCodes,
  }) {
    final sq = <String, dynamic>{};
    final eq = <String, dynamic>{};
    File? photo;

    for (final code in sqCodes) {
      final value = answers[code];
      if (value == null) continue;
      final text = value.toString();
      if (text.isEmpty) continue;
      sq[code] = text;
    }

    for (final code in eqCodes) {
      final value = answers[code];
      if (value == null) continue;

      if (code == 'E2') {
        if (value is Map) {
          final opening = parseOpeningMm(value['opening_mm']);
          if (opening != null) {
            eq[code] = {'opening_mm': opening};
          }
          final p = value['photo'];
          if (p is File) photo = p;
        }
      } else if (value is Map) {
        final scores = <String, dynamic>{};
        value.forEach((area, score) {
          if (score is num) {
            scores[area.toString()] = score.toInt();
          }
        });
        eq[code] = scores;
      } else {
        final text = value.toString();
        if (text.isNotEmpty) eq[code] = text;
      }
    }

    return ConsultationPayload(sq: sq, eq: eq, photo: photo);
  }

  /// Parse bukaan mulut (mm). Menerima `num` atau teks angka desimal biasa
  /// (koma diterima sebagai pemisah desimal). Mengembalikan `int` bila bulat.
  /// Mengembalikan null bila bukan angka.
  static num? parseOpeningMm(dynamic raw) {
    if (raw == null) return null;
    num? value;
    if (raw is num) {
      value = raw;
    } else {
      final text = raw.toString().trim();
      if (!RegExp(r'^\d+([.,]\d+)?$').hasMatch(text)) return null;
      value = num.tryParse(text.replaceAll(',', '.'));
    }
    if (value == null || value.isNaN || value.isInfinite) return null;
    if (value == value.truncate()) return value.truncate();
    return value;
  }

  /// Meratakan [sq] dan [eq] ke notasi kurung untuk multipart, mis.
  /// `{'eq[E1][TMJ]': 1, 'sq[SQ1]': 'Ya'}`. Hanya berisi nilai skalar (tanpa File).
  Map<String, dynamic> toFormFields() {
    return {
      ...flatten(sq, 'sq'),
      ...flatten(eq, 'eq'),
    };
  }

  static Map<String, dynamic> flatten(Map<dynamic, dynamic> map, String prefix) {
    final result = <String, dynamic>{};
    map.forEach((key, value) {
      if (value == null) return;
      if (value is Map) {
        result.addAll(flatten(value, '$prefix[$key]'));
      } else {
        result['$prefix[$key]'] = value;
      }
    });
    return result;
  }

  /// Content type foto berdasarkan ekstensi (png -> image/png, selain itu jpeg).
  static MediaType photoContentType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    return MediaType('image', 'jpeg');
  }

  /// Nama file dari path (mendukung pemisah `/` maupun `\`).
  static String fileNameOf(String path) {
    final index = path.lastIndexOf(RegExp(r'[/\\]'));
    return index < 0 ? path : path.substring(index + 1);
  }
}

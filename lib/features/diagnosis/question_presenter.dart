import '../../core/models/question_model.dart';

/// Mengubah data pertanyaan dari server menjadi teks yang ramah pengguna.
///
/// Nilai yang DIKIRIM ke server tidak pernah diubah (harus persis salah satu
/// `options`); yang diubah hanya teks tampilannya, sama seperti form web.
class QuestionPresenter {
  const QuestionPresenter._();

  /// Label opsi khusus per pertanyaan (cermin `WEB_OPTION_LABELS` di backend).
  static const Map<String, Map<String, String>> _optionLabels = {
    'SQ6': {'Tidak': 'Tidak tentu'},
  };

  static const Map<String, String> _areaLabels = {
    'Temporalis': 'Pelipis',
    'Masseter': 'Pipi',
    'TMJ': 'Sendi rahang',
  };

  static const Map<String, String> _areaHints = {
    'Temporalis': 'Otot temporalis, di samping dahi',
    'Masseter': 'Otot masseter, di depan sudut rahang',
    'TMJ': 'Tepat di depan lubang telinga',
  };

  /// Petunjuk pemeriksaan per kode (teks sama dengan form web).
  static const Map<String, String> _instructions = {
    'E1':
        'Tekan ringan tiap area berikut dengan jari sesuai gambar, lalu pilih '
        'tingkat nyeri yang Anda rasakan.',
    'E2':
        'Buka mulut selebar mungkin, lalu ukur jarak antara ujung gigi depan '
        'atas dan bawah dengan penggaris.',
    'E3':
        'Buka dan tutup mulut beberapa kali. Dengarkan contoh bunyi, lalu '
        'pilih yang paling sesuai dengan yang Anda dengar.',
    'E4':
        'Tekan lebih dalam pada area yang sama, lalu pilih tingkat nyeri yang '
        'Anda rasakan.',
  };

  /// Teks pertanyaan tanpa petunjuk format jawaban di akhir, mis.
  /// "... berlangsung? (Jawaban: < 1 minggu atau >= 1 minggu)".
  static String title(QuestionModel question) {
    final cleaned = question.text
        .replaceAll(RegExp(r'\s*\((?:Jawaban|jawaban)\s*:[^)]*\)\s*$'), '')
        .trim();
    return cleaned.isEmpty ? question.text : cleaned;
  }

  static String? instruction(QuestionModel question) =>
      _instructions[question.code];

  /// Teks tampilan untuk nilai opsi [value] pada pertanyaan [code].
  static String optionLabel(String code, String value) {
    final custom = _optionLabels[code]?[value];
    if (custom != null) return custom;

    final text = value.trim();
    var match = RegExp(r'^>=\s*(.+)$').firstMatch(text);
    if (match != null) return '${_capitalize(match.group(1)!)} atau lebih';
    match = RegExp(r'^<=\s*(.+)$').firstMatch(text);
    if (match != null) return '${_capitalize(match.group(1)!)} atau kurang';
    match = RegExp(r'^<\s*(.+)$').firstMatch(text);
    if (match != null) return 'Kurang dari ${match.group(1)}';
    match = RegExp(r'^>\s*(.+)$').firstMatch(text);
    if (match != null) return 'Lebih dari ${match.group(1)}';
    return text;
  }

  static String areaLabel(String area) => _areaLabels[area] ?? area;

  static String? areaHint(String area) => _areaHints[area];

  /// Label skor ringkas untuk tombol, mis. "1 - Nyeri Ringan" -> "Ringan",
  /// "0 - Tidak Nyeri" -> "Tidak".
  static String shortScoreLabel(String? label) {
    if (label == null) return '';
    var text = label.replaceFirst(RegExp(r'^\s*\d+\s*[-–:]\s*'), '').trim();
    text = text
        .replaceFirst(RegExp(r'^Nyeri\s+', caseSensitive: false), '')
        .replaceFirst(RegExp(r'\s+Nyeri$', caseSensitive: false), '');
    return text;
  }

  static String sectionTitle(int sectionNumber) =>
      sectionNumber == 1 ? 'Pertanyaan gejala' : 'Pemeriksaan mandiri';

  static String _capitalize(String text) =>
      text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
}

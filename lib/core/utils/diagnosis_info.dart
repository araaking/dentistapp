/// Nada hasil: [clear] = tidak ada temuan spesifik, [attention] = ada temuan
/// yang sebaiknya diperiksakan.
enum DiagnosisTone { clear, attention }

/// Penjelasan ramah-pengguna untuk nama diagnosis dari server.
class DiagnosisInfo {
  /// Judul berbahasa Indonesia yang ditampilkan ke pengguna.
  final String title;

  /// Istilah medis asli (ditampilkan kecil di bawah judul), bila ada.
  final String? medicalTerm;
  final String description;
  final DiagnosisTone tone;

  const DiagnosisInfo({
    required this.title,
    required this.description,
    this.medicalTerm,
    this.tone = DiagnosisTone.attention,
  });

  /// Nama diagnosis yang dikirim server bila tidak ada kriteria terpenuhi.
  static const String noneName = 'No specific TMD diagnosis found.';

  static const Map<String, DiagnosisInfo> _known = {
    'Myalgia': DiagnosisInfo(
      title: 'Nyeri otot rahang',
      medicalTerm: 'Myalgia',
      description:
          'Jawaban Anda mengarah ke nyeri pada otot pengunyah, yang umumnya '
          'berkaitan dengan ketegangan atau kelelahan otot rahang.',
    ),
    'Arthralgia': DiagnosisInfo(
      title: 'Nyeri sendi rahang',
      medicalTerm: 'Arthralgia',
      description:
          'Jawaban Anda mengarah ke nyeri pada sendi rahang (sendi '
          'temporomandibular) di depan telinga.',
    ),
    'Headache attributed to TMD (HA-TMD)': DiagnosisInfo(
      title: 'Sakit kepala terkait rahang',
      medicalTerm: 'Headache attributed to TMD',
      description:
          'Jawaban Anda mengarah ke sakit kepala di pelipis yang berkaitan '
          'dengan gangguan sendi rahang dan otot pengunyah.',
    ),
    'Joint-related TMD': DiagnosisInfo(
      title: 'Gangguan sendi rahang',
      medicalTerm: 'Joint-related TMD',
      description:
          'Jawaban Anda mengarah ke gangguan pada struktur sendi rahang, '
          'misalnya bunyi sendi, rahang terkunci, atau bukaan mulut terbatas.',
    ),
    noneName: DiagnosisInfo(
      title: 'Tidak ditemukan tanda TMD spesifik',
      description:
          'Berdasarkan jawaban Anda, tidak ada kriteria gangguan sendi rahang '
          'yang terpenuhi saat ini.',
      tone: DiagnosisTone.clear,
    ),
  };

  /// Info untuk [name]; nama yang tidak dikenal ditampilkan apa adanya.
  static DiagnosisInfo of(String? name) {
    final key = name?.trim() ?? '';
    if (key.isEmpty) return _known[noneName]!;
    return _known[key] ??
        DiagnosisInfo(
          title: key,
          description: 'Penjelasan untuk hasil ini belum tersedia.',
        );
  }
}

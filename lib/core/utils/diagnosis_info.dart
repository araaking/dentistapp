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
    // Nama lama: tidak lagi dihasilkan server, dipertahankan agar konsultasi
    // lama di riwayat tetap tampil dengan penjelasan.
    'Joint-related TMD': DiagnosisInfo(
      title: 'Gangguan sendi rahang',
      medicalTerm: 'Joint-related TMD',
      description:
          'Jawaban Anda mengarah ke gangguan pada struktur sendi rahang, '
          'misalnya bunyi sendi, rahang terkunci, atau bukaan mulut terbatas.',
    ),
    'Degenerative joint disease': DiagnosisInfo(
      title: 'Perubahan degeneratif sendi rahang',
      medicalTerm: 'Degenerative joint disease',
      description:
          'Jawaban Anda mengarah ke perubahan degeneratif pada sendi rahang, '
          'ditandai bunyi kasar seperti pasir (krepitasi) saat rahang '
          'digerakkan; dapat disertai keterbatasan gerak.',
    ),
    'Acute closed lock': DiagnosisInfo(
      title: 'Rahang terkunci tertutup',
      medicalTerm: 'Acute closed lock',
      description:
          'Jawaban Anda mengarah ke bantalan sendi (diskus) yang bergeser dan '
          'tidak kembali ke posisinya, sehingga mulut tidak dapat dibuka lebar '
          '(kurang dari 35 mm).',
    ),
    'Other Disc-based TMD': DiagnosisInfo(
      title: 'Gangguan bantalan sendi rahang',
      medicalTerm: 'Other Disc-based TMD',
      description:
          'Jawaban Anda mengarah ke gangguan pada bantalan sendi (diskus) '
          'rahang, umumnya ditandai bunyi klik saat membuka/menutup mulut atau '
          'riwayat rahang terkunci; dapat disertai keterbatasan gerak.',
    ),
    'Subluxation': DiagnosisInfo(
      title: 'Rahang terkunci terbuka',
      medicalTerm: 'Subluxation',
      description:
          'Jawaban Anda mengarah ke rahang yang pernah terkunci dalam posisi '
          'terbuka lebar dan perlu digeser agar bisa menutup kembali; bila '
          'terkunci terbuka lebih dari beberapa detik disebut luksasi '
          '(dislokasi).',
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

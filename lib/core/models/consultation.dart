import '../utils/constants.dart';

/// Satu konsultasi (hasil pemeriksaan) milik pengguna.
///
/// Parser sengaja toleran karena bentuk respons berbeda antar endpoint:
/// - `GET api/consultations`: `{id, consultation_date, diagnoses: [{name}], e2_photo_url}`
/// - `POST api/consultations`: `{consultation_id, diagnoses: ['Myalgia'], e2_photo_url}`
class Consultation {
  final int? id;
  final DateTime? date;
  final List<String> diagnoses;

  /// URL foto bukaan mulut (privat, butuh header Authorization). Selalu
  /// diarahkan ke host API yang dikonfigurasi, lihat [AppConstants.resolveApiUrl].
  final String? photoUrl;

  const Consultation({
    this.id,
    this.date,
    this.diagnoses = const [],
    this.photoUrl,
  });

  factory Consultation.fromJson(Map<dynamic, dynamic> json) {
    final rawDiagnoses = json['diagnoses'];
    final diagnoses = <String>[];
    if (rawDiagnoses is List) {
      for (final item in rawDiagnoses) {
        final name = item is Map ? item['name'] : item;
        if (name != null && name.toString().trim().isNotEmpty) {
          diagnoses.add(name.toString().trim());
        }
      }
    }

    final rawPhoto = json['e2_photo_url'];
    final rawDate = json['consultation_date'] ?? json['created_at'];

    return Consultation(
      id: _asInt(json['id'] ?? json['consultation_id']),
      date: rawDate == null
          ? null
          : DateTime.tryParse(rawDate.toString())?.toLocal(),
      diagnoses: diagnoses,
      photoUrl: rawPhoto is String && rawPhoto.isNotEmpty
          ? AppConstants.resolveApiUrl(rawPhoto)
          : null,
    );
  }

  /// Diagnosis utama (aturan server menghasilkan paling banyak satu).
  String? get primaryDiagnosis => diagnoses.isEmpty ? null : diagnoses.first;

  Consultation copyWith({DateTime? date}) {
    return Consultation(
      id: id,
      date: date ?? this.date,
      diagnoses: diagnoses,
      photoUrl: photoUrl,
    );
  }

  static int? _asInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

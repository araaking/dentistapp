/// Profil pasien dari `GET/POST/PUT api/patient`.
class Patient {
  final String name;

  /// Tanggal lahir (tanpa jam), atau null bila belum diisi.
  final DateTime? dateOfBirth;

  /// `Male`, `Female`, atau null (nilai persis yang diterima server).
  final String? gender;
  final String? phoneNumber;

  const Patient({
    required this.name,
    this.dateOfBirth,
    this.gender,
    this.phoneNumber,
  });

  factory Patient.fromJson(Map<dynamic, dynamic> json) {
    String? text(dynamic value) {
      final s = value?.toString().trim() ?? '';
      return s.isEmpty ? null : s;
    }

    final dob = text(json['date_of_birth']);
    return Patient(
      name: text(json['name']) ?? '',
      dateOfBirth: dob == null ? null : DateTime.tryParse(dob),
      gender: text(json['gender']),
      phoneNumber: text(json['phone_number']),
    );
  }

  /// Nama depan untuk sapaan.
  String get firstName {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? '' : parts.first;
  }

  /// Inisial (maks. 2 huruf) untuk avatar.
  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    final first = parts.first.substring(0, 1);
    final last = parts.length > 1 ? parts.last.substring(0, 1) : '';
    return (first + last).toUpperCase();
  }

  String get genderLabel => switch (gender) {
    'Male' => 'Laki-laki',
    'Female' => 'Perempuan',
    _ => '-',
  };
}

/// Format tanggal untuk server: `YYYY-MM-DD`.
String toApiDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

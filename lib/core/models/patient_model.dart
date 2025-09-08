class PatientModel {
  final int id;
  final int userId;
  final String name;
  final String? dateOfBirth;
  final String? gender;
  final String? phoneNumber;

  PatientModel({
    required this.id,
    required this.userId,
    required this.name,
    this.dateOfBirth,
    this.gender,
    this.phoneNumber,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      dateOfBirth: json['date_of_birth'],
      gender: json['gender'],
      phoneNumber: json['phone_number'],
    );
  }

  /// Helper method untuk mengubah object menjadi Map,
  /// berguna saat mengirim data untuk create/update.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'phone_number': phoneNumber,
    };
  }
}

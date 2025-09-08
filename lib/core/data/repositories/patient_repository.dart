import 'package:dio/dio.dart';
import '../provider/patient_api_provider.dart';

// Ganti 'dynamic' dengan model Patient Anda.
// import '../../models/patient_model.dart';

class PatientRepository {
  final PatientApiProvider _patientApiProvider;

  PatientRepository(this._patientApiProvider);

  /// Mengambil profil pasien.
  Future<Map<String, dynamic>> getPatientProfile() async {
    try {
      final response = await _patientApiProvider.getPatientProfile();
      // Ganti return type menjadi Future<PatientModel>
      // return PatientModel.fromJson(response.data['patient']);
      return response.data['patient'];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Kasus khusus jika profil belum ada.
        // Anda bisa melempar exception custom atau mengembalikan null.
        throw Exception('Patient profile not found.');
      }
      throw Exception('Failed to get patient profile: ${e.message}');
    }
  }

  /// Membuat profil pasien baru.
  Future<Map<String, dynamic>> createPatientProfile(Map<String, dynamic> data) async {
    try {
      final response = await _patientApiProvider.createPatientProfile(data);
      // return PatientModel.fromJson(response.data['patient']);
      return response.data['patient'];
    } on DioException catch (e) {
      throw Exception('Failed to create patient profile: ${e.response?.data['message']}');
    }
  }

  /// Memperbarui profil pasien.
  Future<Map<String, dynamic>> updatePatientProfile(Map<String, dynamic> data) async {
    try {
      final response = await _patientApiProvider.updatePatientProfile(data);
      // return PatientModel.fromJson(response.data['patient']);
      return response.data['patient'];
    } on DioException catch (e) {
      throw Exception('Failed to update patient profile: ${e.response?.data['message']}');
    }
  }
}

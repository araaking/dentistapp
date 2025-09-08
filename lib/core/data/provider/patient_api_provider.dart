import 'package:dio/dio.dart';

class PatientApiProvider {
  final Dio _dio;

  PatientApiProvider(this._dio);

  /// Mengambil profil pasien milik pengguna yang sedang login.
  Future<Response> getPatientProfile() async {
    try {
      final response = await _dio.get('api/patient');
      return response;
    } on DioException {
      rethrow;
    }
  }

  /// Membuat profil pasien baru.
  /// Mengirim data seperti nama, tanggal lahir, dll.
  Future<Response> createPatientProfile(Map<String, dynamic> patientData) async {
    try {
      final response = await _dio.post(
        'api/patient',
        data: patientData,
      );
      return response;
    } on DioException {
      rethrow;
    }
  }

  /// Memperbarui profil pasien yang sudah ada.
  Future<Response> updatePatientProfile(Map<String, dynamic> patientData) async {
    try {
      final response = await _dio.put(
        'api/patient',
        data: patientData,
      );
      return response;
    } on DioException {
      rethrow;
    }
  }
}

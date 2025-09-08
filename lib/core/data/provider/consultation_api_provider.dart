import 'package:dio/dio.dart';

class ConsultationApiProvider {
  final Dio _dio;

  ConsultationApiProvider(this._dio);

  /// Mengambil riwayat semua konsultasi milik pengguna.
  Future<Response> getConsultationHistory() async {
    try {
      final response = await _dio.get('api/consultations');
      return response;
    } on DioException {
      rethrow;
    }
  }

  /// Mengirim jawaban form untuk membuat konsultasi baru.
  /// `answersData` adalah Map yang berisi 'sq' dan 'eq'.
  /// Ini menggunakan FormData untuk mendukung upload file (foto).
  Future<Response> submitConsultation(FormData formData) async {
    try {
      final response = await _dio.post(
        'api/consultations',
        data: formData,
      );
      return response;
    } on DioException {
      rethrow;
    }
  }

  /// Melihat detail satu konsultasi spesifik.
  Future<Response> getConsultationDetail(int consultationId) async {
    try {
      final response = await _dio.get('api/consultations/$consultationId');
      return response;
    } on DioException {
      rethrow;
    }
  }
}

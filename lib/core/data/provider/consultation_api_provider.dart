import 'package:dio/dio.dart';

class ConsultationApiProvider {
  final Dio _dio;

  ConsultationApiProvider(this._dio);

  /// Mengambil riwayat semua konsultasi milik pengguna.
  Future<Response> getConsultationHistory() {
    return _dio.get('api/consultations');
  }

  /// Mengirim jawaban form untuk membuat konsultasi baru (multipart, agar
  /// foto dapat dikirim sebagai file).
  Future<Response> submitConsultation(FormData formData) {
    return _dio.post(
      'api/consultations',
      data: formData,
      options: Options(contentType: Headers.multipartFormDataContentType),
    );
  }

  /// Melihat detail satu konsultasi spesifik.
  Future<Response> getConsultationDetail(int consultationId) {
    return _dio.get('api/consultations/$consultationId');
  }
}

import 'package:dio/dio.dart';
import '../consultation_payload.dart';
import '../provider/consultation_api_provider.dart';
import '../../errors/exceptions.dart';
import '../../utils/json_utils.dart';

class ConsultationRepository {
  final ConsultationApiProvider _consultationApiProvider;

  ConsultationRepository(this._consultationApiProvider);

  /// Mengambil riwayat konsultasi (terbaru dulu).
  Future<List<dynamic>> getConsultationHistory() async {
    try {
      final response = await _consultationApiProvider.getConsultationHistory();
      final list = asJsonMap(response.data)['consultations'];
      return list is List ? list : <dynamic>[];
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Alias untuk getConsultationHistory (untuk kompatibilitas dengan HistoryScreen)
  Future<List<dynamic>> getConsultations() {
    return getConsultationHistory();
  }

  /// Mengambil detail satu konsultasi.
  Future<Map<String, dynamic>> getConsultationDetail(int consultationId) async {
    try {
      final response =
          await _consultationApiProvider.getConsultationDetail(consultationId);
      return asJsonMap(asJsonMap(response.data)['consultation']);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Mengirim konsultasi (satu request multipart, foto sebagai `e2_photo_file`).
  Future<Map<String, dynamic>> submitConsultation(
      ConsultationPayload payload) async {
    try {
      final fields = payload.toFormFields();

      final photo = payload.photo;
      if (photo != null) {
        fields['e2_photo_file'] = await MultipartFile.fromFile(
          photo.path,
          filename: ConsultationPayload.fileNameOf(photo.path),
          contentType: ConsultationPayload.photoContentType(photo.path),
        );
      }

      final response = await _consultationApiProvider
          .submitConsultation(FormData.fromMap(fields));
      return asJsonMap(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

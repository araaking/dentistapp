import 'package:dio/dio.dart';

import '../../errors/exceptions.dart';
import '../../models/consultation.dart';
import '../../utils/json_utils.dart';
import '../consultation_payload.dart';
import '../provider/consultation_api_provider.dart';

class ConsultationRepository {
  final ConsultationApiProvider _consultationApiProvider;

  ConsultationRepository(this._consultationApiProvider);

  /// Mengambil riwayat konsultasi (terbaru dulu).
  Future<List<Consultation>> getConsultationHistory() async {
    try {
      final response = await _consultationApiProvider.getConsultationHistory();
      final list = asJsonMap(response.data)['consultations'];
      if (list is! List) return const [];
      return list.whereType<Map>().map(Consultation.fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Mengirim konsultasi (satu request multipart, foto sebagai `e2_photo_file`)
  /// dan mengembalikan hasilnya.
  Future<Consultation> submitConsultation(ConsultationPayload payload) async {
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

      final response = await _consultationApiProvider.submitConsultation(
        FormData.fromMap(fields),
      );
      final result = Consultation.fromJson(asJsonMap(response.data));
      // Respons POST tidak memuat tanggal; konsultasi baru saja dibuat.
      return result.date == null
          ? result.copyWith(date: DateTime.now())
          : result;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

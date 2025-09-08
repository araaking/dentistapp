import 'dart:io';
import 'package:dio/dio.dart';
import '../provider/consultation_api_provider.dart';
import 'package:http_parser/http_parser.dart';

// Ganti 'dynamic' dengan model Consultation Anda.
// import '../../models/consultation_model.dart';

class ConsultationRepository {
  final ConsultationApiProvider _consultationApiProvider;

  ConsultationRepository(this._consultationApiProvider);

  /// Mengambil riwayat konsultasi.
  Future<List<dynamic>> getConsultationHistory() async {
    try {
      final response = await _consultationApiProvider.getConsultationHistory();
      // Response-nya adalah list, jadi Anda akan melakukan mapping.
      // return (response.data['consultations'] as List)
      //     .map((json) => ConsultationModel.fromJson(json))
      //     .toList();
      return response.data['consultations'];
    } on DioException catch (e) {
      throw Exception('Failed to get consultation history: ${e.message}');
    }
  }

  /// Mengambil detail satu konsultasi.
  Future<Map<String, dynamic>> getConsultationDetail(int consultationId) async {
    try {
      final response = await _consultationApiProvider.getConsultationDetail(consultationId);
      // return ConsultationModel.fromJson(response.data['consultation']);
      return response.data['consultation'];
    } on DioException catch (e) {
      throw Exception('Failed to get consultation detail: ${e.message}');
    }
  }

  /// Mengirim jawaban konsultasi, termasuk kemungkinan foto.
  Future<Map<String, dynamic>> submitConsultation({
    required Map<String, dynamic> sqAnswers,
    required Map<String, dynamic> eqAnswers,
    File? e2Photo,
  }) async {
    try {
      // Membuat FormData untuk mengirim data dan file.
      final formDataMap = {
        // API Anda mengharapkan format seperti 'sq[SQ1]': 'Ya'
        // Kita perlu meratakan (flatten) map jawaban.
        ..._flattenMap(sqAnswers, 'sq'),
        ..._flattenMap(eqAnswers, 'eq'),
      };

      if (e2Photo != null) {
        String fileName = e2Photo.path.split('/').last;
        formDataMap['e2_photo_file'] = await MultipartFile.fromFile(
          e2Photo.path,
          filename: fileName,
          contentType: MediaType('image', 'jpeg'), // Sesuaikan jika perlu
        );
      }

      final formData = FormData.fromMap(formDataMap);

      final response = await _consultationApiProvider.submitConsultation(formData);
      return response.data;
    } on DioException catch (e) {
      throw Exception('Failed to submit consultation: ${e.response?.data['message']}');
    }
  }

  /// Helper function untuk mengubah map nested menjadi flat untuk FormData.
  /// Contoh: {'E1': {'Temporalis': 1}} menjadi {'eq[E1][Temporalis]': 1}
  Map<String, dynamic> _flattenMap(Map<String, dynamic> map, String prefix) {
    final Map<String, dynamic> flattenedMap = {};
    map.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        flattenedMap.addAll(_flattenMap(value, '$prefix[$key]'));
      } else {
        flattenedMap['$prefix[$key]'] = value;
      }
    });
    return flattenedMap;
  }
}

import 'package:dio/dio.dart';

class QuestionApiProvider {
  final Dio _dio;

  QuestionApiProvider(this._dio);

  /// Mengambil daftar lengkap pertanyaan (SQ & EQ).
  Future<Response> getQuestions() async {
    try {
      final response = await _dio.get('api/questions');
      return response;
    } on DioException {
      rethrow;
    }
  }
}

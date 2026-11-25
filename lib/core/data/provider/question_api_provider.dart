import 'package:dio/dio.dart';

class QuestionApiProvider {
  final Dio _dio;

  QuestionApiProvider(this._dio);

  /// Mengambil daftar lengkap pertanyaan (SQ & EQ).
  Future<Response> getQuestions() {
    return _dio.get('api/questions');
  }
}

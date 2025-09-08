import 'package:dio/dio.dart';
import '../provider/question_api_provider.dart';
import '../../models/question_model.dart';

class QuestionRepository {
  final QuestionApiProvider _questionApiProvider;

  QuestionRepository(this._questionApiProvider);

  /// Mengambil semua pertanyaan untuk form diagnosis.
  Future<AllQuestionsModel> getQuestions() async {
    try {
      final response = await _questionApiProvider.getQuestions();

      // PERBAIKAN: Cek jika data adalah List, ambil elemen pertama.
      // Ini untuk menangani jika API mengembalikan [ { "sq": ..., "eq": ... } ]
      // bukannya { "sq": ..., "eq": ... }
      dynamic responseData = response.data;
      if (responseData is List && responseData.isNotEmpty) {
        responseData = responseData.first;
      }

      // Pastikan data yang akan diparsing adalah Map
      if (responseData is Map<String, dynamic>) {
        return AllQuestionsModel.fromJson(responseData);
      } else {
        // Jika setelah pengecekan data tetap bukan Map, lempar error yang jelas
        throw Exception(
            'Format data pertanyaan tidak valid. Diharapkan Map, diterima ${responseData.runtimeType}');
      }
    } on DioException catch (e) {
      // Menggunakan pesan error dari response jika ada, jika tidak gunakan pesan default Dio
      final errorMessage = e.response?.data['message'] ?? e.message;
      throw Exception('Failed to load questions: $errorMessage');
    } catch (e) {
      // Menangkap error lain yang mungkin terjadi
      throw Exception('An unexpected error occurred: $e');
    }
  }
}

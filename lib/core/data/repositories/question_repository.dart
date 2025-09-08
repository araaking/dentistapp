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
      // Parse the full response into AllQuestionsModel
      return AllQuestionsModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to load questions: ${e.message}');
    }
  }
}

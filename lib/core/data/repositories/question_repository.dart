import 'package:dio/dio.dart';
import '../provider/question_api_provider.dart';
import '../../errors/exceptions.dart';
import '../../models/question_model.dart';
import '../../utils/json_utils.dart';

class QuestionRepository {
  final QuestionApiProvider _questionApiProvider;

  QuestionRepository(this._questionApiProvider);

  /// Mengambil semua pertanyaan untuk form diagnosis.
  Future<AllQuestionsModel> getQuestions() async {
    try {
      final response = await _questionApiProvider.getQuestions();
      final data = asJsonMap(response.data);

      if (!data.containsKey('sq') || !data.containsKey('eq')) {
        throw ApiException(message: 'Data pertanyaan dari server tidak lengkap.');
      }

      try {
        return AllQuestionsModel.fromJson(data);
      } catch (_) {
        throw ApiException(message: 'Format data pertanyaan tidak dikenali.');
      }
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

import 'package:dio/dio.dart';
import '../provider/question_api_provider.dart';
import '../../models/question_model.dart';

class QuestionRepository {
  final QuestionApiProvider _questionApiProvider;

  QuestionRepository(this._questionApiProvider);

  /// Mengambil semua pertanyaan untuk form diagnosis.
  Future<AllQuestionsModel> getQuestions() async {
    print('=== DEBUG: QuestionRepository.getQuestions() called ===');
    try {
      final response = await _questionApiProvider.getQuestions();
      
      // Debug logging untuk melihat response lengkap
      print('API Response status: ${response.statusCode}');
      print('API Response data type: ${response.data.runtimeType}');
      print('API Response data: ${response.data}');
      
      dynamic responseData = response.data;

      // Handle case when API returns error message in different format
      if (responseData is Map && responseData.containsKey('message')) {
        // This might be an error response from API
        throw Exception('API Error: ${responseData['message']}');
      }

      // Handle case when response is a List (unexpected format)
      if (responseData is List) {
        if (responseData.isNotEmpty && responseData.first is Map) {
          responseData = responseData.first;
        } else {
          throw Exception('Failed to load questions: API returned unexpected list format');
        }
      }

      // Ensure we have a Map before parsing
      if (responseData is Map<String, dynamic>) {
        // Validasi bahwa response memiliki struktur yang diharapkan
        if (!responseData.containsKey('sq') || !responseData.containsKey('eq')) {
          throw Exception('Invalid question data: missing sq or eq fields');
        }
        
        try {
          final allQuestions = AllQuestionsModel.fromJson(responseData);
          print('=== DEBUG: Successfully parsed questions ===');
          print('SQ questions: ${allQuestions.sq.length}');
          print('EQ questions: ${allQuestions.eq.length}');
          // Debug each EQ question
          for (var eq in allQuestions.eq) {
            print('EQ ${eq.code}: type=${eq.input.type}, areas=${eq.input.areas}');
          }
          return allQuestions;
        } catch (e) {
          // Specific error handling for parsing issues
          print('Error parsing questions JSON: $e');
          print('Problematic JSON data: $responseData');
          throw Exception('Failed to parse question data: $e');
        }
      } else {
        throw Exception('Invalid question data format. Expected Map, got ${responseData.runtimeType}');
      }
    } on DioException catch (e) {
      // More detailed error handling
      final errorMessage = e.response?.data?['message'] ?? 
                          e.response?.data?.toString() ?? 
                          e.message;
      throw Exception('Failed to load questions: $errorMessage');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }
}
import 'package:dio/dio.dart';
import '../provider/patient_api_provider.dart';

class PatientRepository {
  final PatientApiProvider _patientApiProvider;

  PatientRepository(this._patientApiProvider);

  Future<Map<String, dynamic>> getPatient() async {
    try {
      final response = await _patientApiProvider.getPatient();
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return {'message': 'Profil pasien belum dibuat.'};
      }
      throw Exception('Failed to get patient: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get patient: $e');
    }
  }

  Future<Map<String, dynamic>> createPatient(Map<String, dynamic> data) async {
    try {
      final response = await _patientApiProvider.createPatient(data);
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw Exception('Profil pasien sudah ada.');
      }
      throw Exception('Failed to create patient: ${e.message}');
    } catch (e) {
      throw Exception('Failed to create patient: $e');
    }
  }

  Future<Map<String, dynamic>> updatePatient(Map<String, dynamic> data) async {
    try {
      final response = await _patientApiProvider.updatePatient(data);
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Profil pasien belum dibuat.');
      }
      throw Exception('Failed to update patient: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update patient: $e');
    }
  }
}

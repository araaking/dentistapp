import 'package:dio/dio.dart';
import '../provider/patient_api_provider.dart';
import '../../errors/exceptions.dart';
import '../../utils/json_utils.dart';

class PatientRepository {
  final PatientApiProvider _patientApiProvider;

  PatientRepository(this._patientApiProvider);

  /// Mengambil profil pasien. Bila profil belum dibuat (404), mengembalikan
  /// `{'message': 'Profil pasien belum dibuat.'}` tanpa kunci `patient`.
  Future<Map<String, dynamic>> getPatient() async {
    try {
      final response = await _patientApiProvider.getPatient();
      return asJsonMap(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return {'message': 'Profil pasien belum dibuat.'};
      }
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> createPatient(Map<String, dynamic> data) async {
    try {
      final response = await _patientApiProvider.createPatient(data);
      return asJsonMap(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> updatePatient(Map<String, dynamic> data) async {
    try {
      final response = await _patientApiProvider.updatePatient(data);
      return asJsonMap(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

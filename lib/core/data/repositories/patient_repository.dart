import 'package:dio/dio.dart';

import '../../errors/exceptions.dart';
import '../../models/patient.dart';
import '../../utils/json_utils.dart';
import '../provider/patient_api_provider.dart';

class PatientRepository {
  final PatientApiProvider _patientApiProvider;

  PatientRepository(this._patientApiProvider);

  /// Mengambil profil pasien, atau null bila profil belum dibuat (404).
  Future<Patient?> getPatient() async {
    try {
      final response = await _patientApiProvider.getPatient();
      return _patientFrom(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ApiException.fromDioException(e);
    }
  }

  Future<Patient?> createPatient(Map<String, dynamic> data) async {
    try {
      final response = await _patientApiProvider.createPatient(data);
      return _patientFrom(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Patient?> updatePatient(Map<String, dynamic> data) async {
    try {
      final response = await _patientApiProvider.updatePatient(data);
      return _patientFrom(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  static Patient? _patientFrom(dynamic data) {
    final patient = asJsonMap(data)['patient'];
    return patient is Map ? Patient.fromJson(patient) : null;
  }
}

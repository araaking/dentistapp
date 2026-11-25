import 'package:dio/dio.dart';

class PatientApiProvider {
  final Dio _dio;

  PatientApiProvider(this._dio);

  Future<Response> getPatient() {
    return _dio.get('api/patient');
  }

  Future<Response> createPatient(Map<String, dynamic> data) {
    return _dio.post('api/patient', data: data);
  }

  Future<Response> updatePatient(Map<String, dynamic> data) {
    return _dio.put('api/patient', data: data);
  }
}

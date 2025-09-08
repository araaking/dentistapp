import 'package:dio/dio.dart';
import '../../utils/dio_client.dart';

class PatientApiProvider {
  final Dio _dio;

  PatientApiProvider(this._dio);

  Future<Response> getPatient() async {
    return await _dio.get('/api/patient');
  }

  Future<Response> createPatient(Map<String, dynamic> data) async {
    print('=== DEBUG: Creating patient with data: $data');
    return await _dio.post('/api/patient', data: data);
  }

  Future<Response> updatePatient(Map<String, dynamic> data) async {
    print('=== DEBUG: Updating patient with data: $data');
    return await _dio.put('/api/patient', data: data);
  }
}

import 'package:dio/dio.dart';

class AuthApiProvider {
  // use a private, final Dio instance that matches calls to `_dio`
  final Dio _dio;

  // Asumsi Anda akan menyediakan instance Dio yang sudah dikonfigurasi
  AuthApiProvider(this._dio);

  /// Melakukan request untuk registrasi pengguna baru.
  /// Mengirim email, password, dan name.
  Future<Response> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await _dio.post(
        'api/auth/register',
        data: {
          'email': email,
          'password': password,
          'name': name,
        },
      );
      return response;
    } on DioException {
      // Biarkan repository layer yang menangani DioException
      rethrow;
    }
  }

  /// Melakukan request untuk login pengguna.
  /// Mengirim email dan password.
  Future<Response> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        'api/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );
      return response;
    } on DioException {
      rethrow;
    }
  }

  /// Mengambil detail pengguna yang sedang login.
  /// Membutuhkan token autentikasi di header.
  Future<Response> getMe() async {
    try {
      final response = await _dio.get('api/auth/me');
      return response;
    } on DioException {
      rethrow;
    }
  }

  /// Melakukan request untuk logout pengguna.
  /// Membutuhkan token autentikasi di header.
  Future<Response> logout() async {
    try {
      final response = await _dio.post('api/auth/logout');
      return response;
    } on DioException {
      rethrow;
    }
  }
}

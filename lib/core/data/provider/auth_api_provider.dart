import 'package:dio/dio.dart';
import '../../utils/constants.dart';

/// Lapisan paling bawah: hanya melakukan request HTTP dan mengembalikan
/// [Response]. Error (DioException) dibiarkan naik ke repository untuk dipetakan.
class AuthApiProvider {
  final Dio _dio;

  AuthApiProvider(this._dio);

  /// Request tanpa penanganan 401 otomatis (login/register, validasi sesi,
  /// dan logout menangani 401 sendiri).
  static Options get _skipUnauthorizedHandler => Options(
        extra: {AppConstants.skipUnauthorizedHandlerKey: true},
      );

  /// Registrasi pengguna baru. Field opsional hanya dikirim bila terisi.
  Future<Response> register({
    required String email,
    required String password,
    required String name,
    String? dateOfBirth,
    String? gender,
    String? phoneNumber,
  }) {
    return _dio.post(
      'api/auth/register',
      data: {
        'email': email,
        'password': password,
        'name': name,
        if (dateOfBirth != null && dateOfBirth.isNotEmpty)
          'date_of_birth': dateOfBirth,
        if (gender != null && gender.isNotEmpty) 'gender': gender,
        if (phoneNumber != null && phoneNumber.isNotEmpty)
          'phone_number': phoneNumber,
      },
      options: _skipUnauthorizedHandler,
    );
  }

  /// Login pengguna.
  Future<Response> login({
    required String email,
    required String password,
  }) {
    return _dio.post(
      'api/auth/login',
      data: {
        'email': email,
        'password': password,
      },
      options: _skipUnauthorizedHandler,
    );
  }

  /// Mengambil data pengguna yang sedang login (dipakai untuk memvalidasi
  /// token tersimpan saat aplikasi dibuka).
  Future<Response> getMe() {
    return _dio.get('api/auth/me', options: _skipUnauthorizedHandler);
  }

  /// Logout (mencabut token saat ini di server).
  Future<Response> logout() {
    return _dio.post('api/auth/logout', options: _skipUnauthorizedHandler);
  }

  /// Menghapus akun secara permanen. Membutuhkan password saat ini.
  Future<Response> deleteAccount(String password) {
    return _dio.delete('api/account', data: {'password': password});
  }
}

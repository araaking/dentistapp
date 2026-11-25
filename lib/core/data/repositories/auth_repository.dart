import 'package:dio/dio.dart';
import '../provider/auth_api_provider.dart';
import '../../errors/exceptions.dart';
import '../../utils/json_utils.dart';

class AuthRepository {
  final AuthApiProvider _authApiProvider;

  AuthRepository(this._authApiProvider);

  /// Login user dan mengembalikan data user beserta token.
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _authApiProvider.login(
        email: email,
        password: password,
      );
      return asJsonMap(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Registrasi user baru. Field opsional hanya dikirim bila terisi.
  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String name, {
    String? dateOfBirth,
    String? gender,
    String? phoneNumber,
  }) async {
    try {
      final response = await _authApiProvider.register(
        email: email,
        password: password,
        name: name,
        dateOfBirth: dateOfBirth,
        gender: gender,
        phoneNumber: phoneNumber,
      );
      return asJsonMap(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Mendapatkan data user yang sedang login.
  Future<Map<String, dynamic>> getMe() async {
    try {
      final response = await _authApiProvider.getMe();
      return asJsonMap(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Logout user (mencabut token di server).
  Future<void> logout() async {
    try {
      await _authApiProvider.logout();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Menghapus akun secara permanen.
  Future<void> deleteAccount(String password) async {
    try {
      await _authApiProvider.deleteAccount(password);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

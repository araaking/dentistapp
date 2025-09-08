import 'package:dio/dio.dart';
import '../provider/auth_api_provider.dart';
import '../../errors/exceptions.dart';
import '../../models/user_model.dart';

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
      // Di sini Anda akan mem-parsing response.data menjadi UserModel
      // dan menyimpan tokennya (misal: di SharedPreferences).
      return response.data;
    } on DioException catch (e) {
      // Ekstrak pesan error dengan aman tanpa mengasumsikan bentuk data
      final data = e.response?.data;
      String? msg;
      if (data is Map) {
        final map = Map<String, dynamic>.from(data as Map);
        if (map['message'] is String) msg = map['message'] as String;
        else if (map['error'] is String) msg = map['error'] as String;
      }
      msg ??= e.message;
      throw ApiException(message: 'Login failed: ${msg ?? 'Unknown error'}', statusCode: e.response?.statusCode);
    }
  }

  /// Registrasi user baru.
  Future<Map<String, dynamic>> register(String email, String password) async {
    try {
      final response = await _authApiProvider.register(
        email: email,
        password: password,
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Registration failed: ${e.response?.data['message']}');
    }
  }

  /// Mendapatkan data user yang sedang login.
  Future<Map<String, dynamic>> getMe() async {
    try {
      final response = await _authApiProvider.getMe();
      // Ganti return type menjadi Future<UserModel>
      // return UserModel.fromJson(response.data);
      return response.data;
    } on DioException catch (e) {
      throw Exception('Failed to get user data: ${e.message}');
    }
  }

  /// Logout user.
  Future<void> logout() async {
    try {
      await _authApiProvider.logout();
      // Di sini Anda akan menghapus token yang tersimpan.
    } on DioException catch (e) {
      throw Exception('Logout failed: ${e.message}');
    }
  }
}

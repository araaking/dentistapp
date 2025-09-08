import 'package:dio/dio.dart';
import '../../features/authentication/provider/auth_provider.dart';
import 'constants.dart';

class DioClient {
  final Dio _dio;
  final AuthProvider? _authProvider;

  DioClient(this._dio, [this._authProvider]) {
    _dio.options.baseUrl = AppConstants.baseUrl;
    _dio.options.headers['Accept'] = 'application/json';
    _dio.options.headers['Content-Type'] = 'application/json';

    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) {
          if (_authProvider?.token != null) {
            options.headers['Authorization'] = 'Bearer ${_authProvider!.token}';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          // Anda bisa menangani error 401 di sini, misalnya dengan refresh token
          return handler.next(e);
        },
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
      ),
    );
  }

  Dio get dio => _dio;
}

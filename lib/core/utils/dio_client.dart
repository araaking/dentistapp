import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../storage/token_storage.dart';
import 'constants.dart';

class DioClient {
  final Dio _dio;
  final TokenStorage _tokenStorage;

  /// Dipanggil saat server menjawab 401 untuk request terautentikasi
  /// (kecuali login/register/validasi sesi/logout).
  final Future<void> Function()? _onUnauthorized;

  DioClient(
    this._dio,
    this._tokenStorage, {
    this._onUnauthorized,
  }) {
    final base = AppConstants.baseUrl;
    _dio.options.baseUrl = base.endsWith('/') ? base : '$base/';
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.sendTimeout = const Duration(seconds: 60);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.headers['Accept'] = 'application/json';
    _dio.options.headers['Content-Type'] = 'application/json';

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _tokenStorage.token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (DioException e, handler) async {
          final skip =
              e.requestOptions.extra[AppConstants.skipUnauthorizedHandlerKey] ==
                  true;
          final hadToken = e.requestOptions.headers['Authorization'] != null;
          if (e.response?.statusCode == 401 && hadToken && !skip) {
            final callback = _onUnauthorized;
            if (callback != null) {
              try {
                await callback();
              } catch (_) {
                // Penanganan sesi tidak boleh menutupi error asli.
              }
            }
          }
          handler.next(e);
        },
      ),
    );

    // Log hanya di build debug, tanpa header/body request agar password,
    // token Bearer, dan data kesehatan tidak pernah tercatat.
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          request: false,
          requestHeader: false,
          requestBody: false,
          responseHeader: false,
          responseBody: false,
          error: true,
          logPrint: (object) => debugPrint(object.toString()),
        ),
      );
    }
  }

  Dio get dio => _dio;
}

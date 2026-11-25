import 'dart:io';

import 'package:dio/dio.dart';

const String _networkMessage =
    'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';

/// Exception base class untuk semua error yang berhubungan dengan API.
///
/// [toString] mengembalikan [message] apa adanya (tanpa prefix "Exception:")
/// sehingga aman ditampilkan langsung ke pengguna.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  /// Pesan pertama untuk tiap field pada error validasi 422
  /// (kunci memakai notasi titik, mis. `eq.E2.opening_mm`).
  final Map<String, String> fieldErrors;

  ApiException({
    required this.message,
    this.statusCode,
    this.fieldErrors = const {},
  });

  /// Memetakan [DioException] (termasuk body error Laravel) ke subclass
  /// [ApiException] yang sesuai.
  factory ApiException.fromDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException();
      case DioExceptionType.badCertificate:
        return NetworkException(
          message: 'Koneksi ke server tidak aman (sertifikat tidak valid).',
        );
      case DioExceptionType.cancel:
        return ApiException(message: 'Permintaan dibatalkan.');
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        break;
    }

    final response = e.response;
    if (response == null) {
      if (e.error is SocketException) return NetworkException();
      return ApiException(message: 'Terjadi kesalahan yang tidak terduga.');
    }

    final status = response.statusCode ?? 0;
    final data = response.data;
    final bodyMessage = _bodyMessage(data);

    if (status == 401) {
      return UnauthorizedException();
    }
    if (status == 403) {
      final msg = (bodyMessage == null ||
              bodyMessage == 'This action is unauthorized.')
          ? 'Akses ditolak.'
          : bodyMessage;
      return ForbiddenException(message: msg);
    }
    if (status == 404) {
      return NotFoundException(message: bodyMessage ?? 'Data tidak ditemukan.');
    }
    if (status == 409) {
      return ConflictException(
        message: bodyMessage ?? 'Terjadi konflik data.',
      );
    }
    if (status == 422) {
      final fields = _fieldErrors(data);
      final msg = fields.isNotEmpty
          ? fields.values.first
          : (bodyMessage ?? 'Data yang dikirim tidak valid.');
      return BadRequestException(
        message: msg,
        statusCode: 422,
        fieldErrors: fields,
      );
    }
    if (status == 429) {
      final retryAfter =
          int.tryParse(response.headers.value('retry-after')?.trim() ?? '');
      return RateLimitException(retryAfterSeconds: retryAfter);
    }
    if (status >= 500) {
      return ServerException(statusCode: status);
    }
    return BadRequestException(
      message: bodyMessage ?? 'Permintaan tidak valid.',
      statusCode: status == 0 ? 400 : status,
    );
  }

  /// Mengubah error apa pun menjadi pesan yang aman ditampilkan ke pengguna.
  static String messageOf(Object error) {
    if (error is ApiException) return error.message;
    return 'Terjadi kesalahan yang tidak terduga. Silakan coba lagi.';
  }

  static String? _bodyMessage(dynamic data) {
    if (data is Map) {
      final m = data['message'];
      if (m is String && m.trim().isNotEmpty) return m.trim();
    }
    return null;
  }

  static Map<String, String> _fieldErrors(dynamic data) {
    final result = <String, String>{};
    if (data is Map && data['errors'] is Map) {
      (data['errors'] as Map).forEach((key, value) {
        String? first;
        if (value is List && value.isNotEmpty) {
          first = value.first?.toString();
        } else if (value is String) {
          first = value;
        }
        if (first != null && first.isNotEmpty) {
          result[key.toString()] = first;
        }
      });
    }
    return result;
  }

  @override
  String toString() => message;
}

/// Dilempar saat terjadi error di sisi server (5xx).
class ServerException extends ApiException {
  ServerException({
    super.message = 'Terjadi kesalahan pada server. Coba lagi nanti.',
    super.statusCode = 500,
  });
}

/// Dilempar saat request tidak valid atau data yang dikirim salah (400, 422).
class BadRequestException extends ApiException {
  BadRequestException({
    super.message = 'Permintaan tidak valid.',
    super.statusCode = 400,
    super.fieldErrors = const {},
  });
}

/// Dilempar saat resource yang diminta tidak ditemukan (404).
class NotFoundException extends ApiException {
  NotFoundException({super.message = 'Data tidak ditemukan.'})
      : super(statusCode: 404);
}

/// Dilempar saat pengguna tidak terautentikasi (401).
class UnauthorizedException extends ApiException {
  UnauthorizedException({
    super.message = 'Sesi Anda telah berakhir, silakan login kembali.',
  }) : super(statusCode: 401);
}

/// Dilempar saat pengguna tidak berhak mengakses resource (403).
class ForbiddenException extends ApiException {
  ForbiddenException({super.message = 'Akses ditolak.'})
      : super(statusCode: 403);
}

/// Dilempar saat terjadi konflik data, mis. profil sudah ada (409).
class ConflictException extends ApiException {
  ConflictException({super.message = 'Terjadi konflik data.'})
      : super(statusCode: 409);
}

/// Dilempar saat terlalu banyak request (429).
class RateLimitException extends ApiException {
  final int? retryAfterSeconds;

  RateLimitException({this.retryAfterSeconds})
      : super(
          message: retryAfterSeconds != null
              ? 'Terlalu banyak percobaan. Coba lagi dalam $retryAfterSeconds detik.'
              : 'Terlalu banyak percobaan. Coba lagi nanti.',
          statusCode: 429,
        );
}

/// Dilempar saat server tidak dapat dijangkau (tanpa koneksi / timeout).
class NetworkException extends ApiException {
  NetworkException({super.message = _networkMessage});
}

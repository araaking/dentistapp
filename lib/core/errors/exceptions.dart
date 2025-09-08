/// Exception base class untuk semua error yang berhubungan dengan API.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException({required this.message, this.statusCode});

  @override
  String toString() => 'ApiException: $message (Status Code: $statusCode)';
}

/// Dilempar saat terjadi error di sisi server (5xx).
class ServerException extends ApiException {
  ServerException({String message = 'Terjadi kesalahan pada server.'})
      : super(message: message, statusCode: 500);
}

/// Dilempar saat request tidak valid atau data yang dikirim salah (400, 422).
class BadRequestException extends ApiException {
  BadRequestException({String message = 'Permintaan tidak valid.'})
      : super(message: message, statusCode: 400);
}

/// Dilempar saat resource yang diminta tidak ditemukan (404).
class NotFoundException extends ApiException {
  NotFoundException({String message = 'Data tidak ditemukan.'})
      : super(message: message, statusCode: 404);
}

/// Dilempar saat pengguna tidak terautentikasi (401).
class UnauthorizedException extends ApiException {
  UnauthorizedException({String message = 'Sesi Anda telah berakhir, silahkan login kembali.'})
      : super(message: message, statusCode: 401);
}

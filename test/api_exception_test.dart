import 'package:dentistapp/core/errors/exceptions.dart';
import 'package:dentistapp/core/utils/constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

DioException badResponse(
  int status,
  dynamic data, {
  Map<String, List<String>> headers = const {},
}) {
  final request = RequestOptions(path: 'api/test');
  return DioException(
    requestOptions: request,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: request,
      statusCode: status,
      data: data,
      headers: Headers.fromMap(headers),
    ),
  );
}

void main() {
  group('ApiException.fromDioException', () {
    test('422 memakai pesan pertama dari errors', () {
      final e = ApiException.fromDioException(badResponse(422, {
        'message': 'The email field is required. (and 1 more error)',
        'errors': {
          'email': ['The email field is required.'],
          'password': ['The password field must be at least 8 characters.'],
        },
      }));

      expect(e, isA<BadRequestException>());
      expect(e.statusCode, 422);
      expect(e.message, 'The email field is required.');
      expect(e.fieldErrors['password'],
          'The password field must be at least 8 characters.');
    });

    test('422 tanpa errors memakai message', () {
      final e = ApiException.fromDioException(
          badResponse(422, {'message': 'Data tidak valid.'}));
      expect(e.message, 'Data tidak valid.');
    });

    test('422 password salah pada hapus akun', () {
      final e = ApiException.fromDioException(badResponse(422, {
        'errors': {
          'password': ['Password salah.'],
        },
      }));
      expect(e.fieldErrors['password'], 'Password salah.');
      expect(e.message, 'Password salah.');
    });

    test('429 membaca header Retry-After', () {
      final e = ApiException.fromDioException(badResponse(
        429,
        {'message': 'Too Many Attempts.'},
        headers: {
          'retry-after': ['30'],
        },
      ));

      expect(e, isA<RateLimitException>());
      expect((e as RateLimitException).retryAfterSeconds, 30);
      expect(e.message, 'Terlalu banyak percobaan. Coba lagi dalam 30 detik.');
    });

    test('429 tanpa Retry-After', () {
      final e = ApiException.fromDioException(
          badResponse(429, {'message': 'Too Many Attempts.'}));
      expect(e.message, 'Terlalu banyak percobaan. Coba lagi nanti.');
    });

    test('401 menjadi UnauthorizedException', () {
      final e = ApiException.fromDioException(
          badResponse(401, {'message': 'Unauthenticated.'}));
      expect(e, isA<UnauthorizedException>());
      expect(e.message, 'Sesi Anda telah berakhir, silakan masuk kembali.');
    });

    test('403 dan 404 memakai pesan dari body', () {
      final forbidden = ApiException.fromDioException(
          badResponse(403, {'message': 'Akses ditolak.'}));
      expect(forbidden, isA<ForbiddenException>());

      final notFound = ApiException.fromDioException(
          badResponse(404, {'message': 'Profil pasien belum dibuat.'}));
      expect(notFound, isA<NotFoundException>());
      expect(notFound.message, 'Profil pasien belum dibuat.');
    });

    test('409 menjadi ConflictException', () {
      final e = ApiException.fromDioException(
          badResponse(409, {'message': 'Profil pasien sudah ada.'}));
      expect(e, isA<ConflictException>());
      expect(e.message, 'Profil pasien sudah ada.');
    });

    test('5xx menjadi ServerException', () {
      final e = ApiException.fromDioException(
          badResponse(500, {'message': 'Server Error'}));
      expect(e, isA<ServerException>());
      expect(e.statusCode, 500);
    });

    test('error koneksi dan timeout menjadi NetworkException', () {
      const expected =
          'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
      for (final type in [
        DioExceptionType.connectionError,
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        final e = ApiException.fromDioException(DioException(
          requestOptions: RequestOptions(path: 'api/test'),
          type: type,
        ));
        expect(e, isA<NetworkException>());
        expect(e.message, expected);
      }
    });

    test('toString tidak memakai prefix "Exception:"', () {
      final e = ApiException.fromDioException(
          badResponse(404, {'message': 'Tidak ada.'}));
      expect(e.toString(), 'Tidak ada.');
    });
  });

  test('ApiException.messageOf menyembunyikan error non-API', () {
    expect(ApiException.messageOf(NetworkException()),
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.');
    expect(ApiException.messageOf(StateError('rahasia')),
        isNot(contains('rahasia')));
  });

  test('resolveApiUrl selalu memakai host dari baseUrl', () {
    final resolved = AppConstants.resolveApiUrl(
        'http://localhost/api/consultations/12/photo');
    final uri = Uri.parse(resolved);
    expect(uri.host, Uri.parse(AppConstants.baseUrl).host);
    expect(uri.path, '/api/consultations/12/photo');
  });
}

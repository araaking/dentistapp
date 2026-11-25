class AppConstants {
  /// URL dasar API. Default mengarah ke server produksi.
  ///
  /// Dapat diganti saat build/run dengan:
  /// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/`
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://dentist.croloze.com/',
  );

  /// Batas ukuran foto yang diterima server (5 MB).
  static const int maxPhotoBytes = 5 * 1024 * 1024;

  /// Kunci `RequestOptions.extra` untuk melewati penanganan 401 otomatis
  /// (dipakai oleh endpoint login/register, validasi sesi, dan logout).
  static const String skipUnauthorizedHandlerKey = 'skipUnauthorizedHandler';

  /// Mengubah URL absolut dari server (mis. `e2_photo_url`) agar selalu
  /// mengarah ke host yang dikonfigurasi di [baseUrl]. Dengan begitu token
  /// Bearer tidak pernah terkirim ke host lain.
  static String resolveApiUrl(String url) {
    final uri = Uri.tryParse(url);
    final base = Uri.tryParse(baseUrl);
    if (uri == null || base == null || base.host.isEmpty) return url;
    return Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: uri.path,
      query: uri.hasQuery ? uri.query : null,
    ).toString();
  }
}

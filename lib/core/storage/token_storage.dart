import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Menyimpan token API di penyimpanan aman (Keychain / Keystore) dan
/// menyediakan salinan di memori agar dapat dibaca secara sinkron oleh
/// interceptor Dio. Dipakai bersama oleh `AuthProvider` dan `DioClient`.
class TokenStorage {
  static const String _tokenKey = 'auth_token';

  final FlutterSecureStorage _storage;
  String? _token;

  TokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  /// Token saat ini (hanya terisi setelah [load] atau [save]).
  String? get token => _token;

  /// Membaca token dari penyimpanan aman ke memori.
  Future<String?> load() async {
    try {
      _token = await _storage.read(key: _tokenKey);
    } catch (_) {
      _token = null;
    }
    return _token;
  }

  Future<void> save(String token) async {
    _token = token;
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (_) {
      // Token tetap ada di memori untuk sesi ini.
    }
  }

  Future<void> clear() async {
    _token = null;
    try {
      await _storage.delete(key: _tokenKey);
    } catch (_) {
      // Abaikan: token di memori sudah dihapus.
    }
  }
}

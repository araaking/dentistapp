import 'package:flutter/foundation.dart';

import '../../../core/data/repositories/auth_repository.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/session/session_manager.dart';
import '../../../core/storage/token_storage.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

/// Hasil pemulihan sesi saat aplikasi dibuka.
enum SessionRestoreResult { authenticated, unauthenticated, networkError }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final TokenStorage _tokenStorage;
  final SessionManager _session;

  AuthProvider(this._authRepository, this._tokenStorage, this._session) {
    // Saat sesi dibersihkan (logout, hapus akun, 401) status auth ikut reset.
    _session.addClearListener(_onSessionCleared);
  }

  static const Duration _logoutTimeout = Duration(seconds: 6);

  AuthState _state = AuthState.initial;
  String _errorMessage = '';
  String? _email;

  AuthState get state => _state;
  String get errorMessage => _errorMessage;
  String? get token => _tokenStorage.token;

  /// Email akun yang sedang login (untuk ditampilkan di Profil).
  String? get email => _email;
  bool get isAuthenticated =>
      _state == AuthState.authenticated && _tokenStorage.token != null;

  void _onSessionCleared() {
    _state = AuthState.unauthenticated;
    _errorMessage = '';
    _email = null;
    notifyListeners();
  }

  /// Dipanggil oleh splash screen: membaca token tersimpan lalu memvalidasinya
  /// dengan `GET api/auth/me`.
  Future<SessionRestoreResult> restoreSession() async {
    final stored = await _tokenStorage.load();
    if (stored == null || stored.isEmpty) {
      _state = AuthState.unauthenticated;
      notifyListeners();
      return SessionRestoreResult.unauthenticated;
    }

    try {
      final me = await _authRepository.getMe();
      _email = _emailFrom(me);
      _state = AuthState.authenticated;
      _errorMessage = '';
      notifyListeners();
      return SessionRestoreResult.authenticated;
    } on UnauthorizedException {
      await _tokenStorage.clear();
      _state = AuthState.unauthenticated;
      notifyListeners();
      return SessionRestoreResult.unauthenticated;
    } on NetworkException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return SessionRestoreResult.networkError;
    } on ApiException catch (e) {
      // Kesalahan server/lainnya: token belum tentu tidak valid, beri
      // kesempatan mencoba lagi.
      _errorMessage = e.message;
      notifyListeners();
      return SessionRestoreResult.networkError;
    } catch (_) {
      _errorMessage =
          'Terjadi kesalahan yang tidak terduga. Silakan coba lagi.';
      notifyListeners();
      return SessionRestoreResult.networkError;
    }
  }

  Future<void> login(String email, String password) async {
    _state = AuthState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await _authRepository.login(email, password);
      await _saveTokenFrom(response, 'Login gagal: token tidak ditemukan.');
    } on BadRequestException catch (e) {
      _state = AuthState.error;
      // 422 pada login berarti kredensial salah.
      _errorMessage = e.statusCode == 422
          ? 'Email atau password salah.'
          : e.message;
    } on ApiException catch (e) {
      _state = AuthState.error;
      _errorMessage = e.message;
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = ApiException.messageOf(e);
    } finally {
      notifyListeners();
    }
  }

  Future<void> register(
    String email,
    String password,
    String name, {
    String? dateOfBirth,
    String? gender,
    String? phoneNumber,
  }) async {
    _state = AuthState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await _authRepository.register(
        email,
        password,
        name,
        dateOfBirth: dateOfBirth,
        gender: gender,
        phoneNumber: phoneNumber,
      );
      // Profil pasien dibuat otomatis oleh backend.
      await _saveTokenFrom(
        response,
        'Registrasi gagal: token tidak ditemukan.',
      );
    } on ApiException catch (e) {
      _state = AuthState.error;
      _errorMessage = _registerMessage(e);
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = ApiException.messageOf(e);
    } finally {
      notifyListeners();
    }
  }

  /// Pesan validasi server berbahasa Inggris; terjemahkan yang paling umum.
  static String _registerMessage(ApiException e) {
    final emailError = e.fieldErrors['email'];
    if (emailError != null && emailError.contains('already been taken')) {
      return 'Email ini sudah terdaftar. Silakan masuk dengan email tersebut.';
    }
    if (emailError != null) return 'Format email tidak valid.';
    if (e.fieldErrors.containsKey('password')) {
      return 'Password minimal 8 karakter.';
    }
    return e.message;
  }

  Future<void> _saveTokenFrom(
    Map<String, dynamic> response,
    String missingMessage,
  ) async {
    final token = response['token'];
    if (token is String && token.isNotEmpty) {
      await _tokenStorage.save(token);
      _email = _emailFrom(response['user']);
      _state = AuthState.authenticated;
    } else {
      _state = AuthState.error;
      _errorMessage = missingMessage;
    }
  }

  static String? _emailFrom(dynamic user) {
    final email = user is Map ? user['email'] : null;
    return email is String && email.isNotEmpty ? email : null;
  }

  /// Menghapus pesan error lama (dipanggil saat berpindah layar login/daftar).
  void clearError() {
    if (_state != AuthState.error) return;
    _state = AuthState.unauthenticated;
    _errorMessage = '';
    notifyListeners();
  }

  /// Logout: mencabut token di server (error diabaikan), lalu menghapus token
  /// dan seluruh state pengguna (profil, diagnosis) dari perangkat.
  Future<void> logout() async {
    try {
      if (_tokenStorage.token != null) {
        // Dibatasi agar pengguna tidak menunggu lama saat offline.
        await _authRepository.logout().timeout(_logoutTimeout);
      }
    } catch (_) {
      // Abaikan error saat logout; yang penting sesi lokal dihapus.
    } finally {
      await _session.clear();
    }
  }

  /// Menghapus sesi tersimpan tanpa menghubungi server (dipakai saat server
  /// tidak terjangkau dan pengguna ingin masuk dengan akun lain).
  Future<void> forgetSession() => _session.clear();

  /// Menghapus akun secara permanen. Melempar [ApiException] bila gagal
  /// (mis. 422 "Password salah."). Bila sukses, sesi lokal dibersihkan.
  Future<void> deleteAccount(String password) async {
    await _authRepository.deleteAccount(password);
    await _session.clear();
  }
}

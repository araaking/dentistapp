import 'package:flutter/material.dart';
import '../../../core/data/repositories/auth_repository.dart';
import '../../../core/errors/exceptions.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthProvider(this._authRepository);

  AuthState _state = AuthState.initial;
  String _errorMessage = '';
  String? _token;

  AuthState get state => _state;
  String get errorMessage => _errorMessage;
  String? get token => _token;
  bool get isAuthenticated => _state == AuthState.authenticated && _token != null;

  Future<void> login(String email, String password) async {
    _state = AuthState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await _authRepository.login(email, password);
      _token = response['token'];

      if (_token != null) {
        _state = AuthState.authenticated;
      } else {
        _state = AuthState.error;
        _errorMessage = 'Login failed: Token not found in response.';
      }
    } on ApiException catch (e) {
      _state = AuthState.error;
      _errorMessage = e.message;
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = 'An unexpected error occurred: $e';
    } finally {
      notifyListeners();
    }
  }

  Future<void> register(String email, String password, String name) async {
    _state = AuthState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await _authRepository.register(email, password, name);
      _token = response['token'];

      if (_token != null) {
        _state = AuthState.authenticated;
        // Patient sudah dibuat otomatis oleh backend, tidak perlu createPatient lagi
      } else {
        _state = AuthState.error;
        _errorMessage = 'Register failed: Token not found in response.';
      }
    } on ApiException catch (e) {
      _state = AuthState.error;
      _errorMessage = e.message;
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = 'An unexpected error occurred: $e';
    } finally {
      notifyListeners();
    }
  }


  Future<void> logout() async {
    if (_token == null) return;
    try {
      await _authRepository.logout();
    } catch (e) {
      // Abaikan error saat logout, yang penting token lokal dihapus
    } finally {
      _token = null;
      _state = AuthState.unauthenticated;
      notifyListeners();
    }
  }
}

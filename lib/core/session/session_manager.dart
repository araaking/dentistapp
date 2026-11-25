import 'package:material_ui/material_ui.dart';

import '../storage/token_storage.dart';
import '../theme/app_colors.dart';

/// Mengelola siklus hidup sesi: menghapus token + seluruh state pengguna
/// (profil, diagnosis, auth) saat logout / sesi berakhir, dan mengarahkan
/// pengguna ke layar login saat server menjawab 401.
class SessionManager {
  final TokenStorage tokenStorage;
  final GlobalKey<NavigatorState> navigatorKey;
  final GlobalKey<ScaffoldMessengerState> messengerKey;

  final List<VoidCallback> _clearListeners = [];
  bool _expiring = false;

  SessionManager({
    required this.tokenStorage,
    required this.navigatorKey,
    required this.messengerKey,
  });

  /// Mendaftarkan callback yang dipanggil setiap sesi dibersihkan
  /// (mis. mengosongkan ProfileProvider / DiagnosisProvider).
  void addClearListener(VoidCallback listener) {
    _clearListeners.add(listener);
  }

  /// Menghapus token (memori + secure storage) dan seluruh state pengguna.
  Future<void> clear() async {
    await tokenStorage.clear();
    for (final listener in List<VoidCallback>.of(_clearListeners)) {
      listener();
    }
  }

  /// Dipanggil saat server menjawab 401: bersihkan sesi lalu kembali ke login
  /// dengan SnackBar penjelasan.
  Future<void> expire() async {
    if (_expiring) return;
    _expiring = true;
    try {
      await clear();
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
      messengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Sesi Anda telah berakhir, silakan masuk kembali.'),
            backgroundColor: AppColors.danger,
          ),
        );
    } finally {
      _expiring = false;
    }
  }
}

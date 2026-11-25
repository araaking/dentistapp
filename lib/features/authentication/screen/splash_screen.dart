import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/app_widgets.dart';
import '../provider/auth_provider.dart';

/// Layar awal: membaca token tersimpan, memvalidasinya ke server
/// (`GET api/auth/me`), lalu menuju /home atau /login.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _checking = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;
    setState(() {
      _checking = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();
    final navigator = Navigator.of(context);
    final result = await auth.restoreSession();
    if (!mounted) return;

    switch (result) {
      case SessionRestoreResult.authenticated:
        navigator.pushReplacementNamed('/home');
      case SessionRestoreResult.unauthenticated:
        navigator.pushReplacementNamed('/login');
      case SessionRestoreResult.networkError:
        setState(() {
          _checking = false;
          _error = auth.errorMessage;
        });
    }
  }

  /// Keluar dari sesi tersimpan lalu ke layar masuk.
  Future<void> _useAnotherAccount() async {
    final auth = context.read<AuthProvider>();
    final navigator = Navigator.of(context);
    await auth.forgetSession();
    navigator.pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.overlayStyle,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLogo(size: 88),
                  const SizedBox(height: AppSpacing.xl),
                  Text('Dentist App', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: AppSpacing.xxl),
                  if (_checking)
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                  else ...[
                    Text(
                      _error ?? 'Terjadi kesalahan.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppButton(label: 'Coba Lagi', onPressed: _bootstrap),
                    const SizedBox(height: AppSpacing.xs),
                    TextButton(
                      onPressed: _useAnotherAccount,
                      child: const Text('Masuk dengan akun lain'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

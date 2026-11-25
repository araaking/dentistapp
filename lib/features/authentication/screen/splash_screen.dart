import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
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
        break;
      case SessionRestoreResult.unauthenticated:
        navigator.pushReplacementNamed('/login');
        break;
      case SessionRestoreResult.networkError:
        setState(() {
          _checking = false;
          _error = auth.errorMessage;
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.health_and_safety_outlined,
                    size: 80, color: AppColors.primary),
                const SizedBox(height: 16),
                const Text(
                  'Dentistapp',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 32),
                if (_checking)
                  const CircularProgressIndicator(color: AppColors.primary)
                else ...[
                  Text(
                    _error ?? 'Terjadi kesalahan.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _bootstrap,
                    child: const Text('Coba Lagi'),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pushReplacementNamed('/login'),
                    child: const Text('Login ulang'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

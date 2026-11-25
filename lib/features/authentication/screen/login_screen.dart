import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/app_widgets.dart';
import '../provider/auth_provider.dart';
import '../widgets/auth_fields.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final navigator = Navigator.of(context);
    await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (!mounted) return;

    if (authProvider.state == AuthState.authenticated) {
      TextInput.finishAutofillContext();
      navigator.pushNamedAndRemoveUntil('/home', (route) => false);
    }
    // Kegagalan ditampilkan sebaris di atas tombol (lihat build).
  }

  void _openRegister() {
    context.read<AuthProvider>().clearError();
    Navigator.of(context).pushNamed('/register');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final loading = auth.state == AuthState.loading;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.overlayStyle,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.xl,
              ),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: AppLogo(size: 64),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'Masuk ke Dentist App',
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs + 2),
                      Text(
                        'Periksa kesehatan sendi rahang Anda secara mandiri.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      EmailField(
                        controller: _emailController,
                        enabled: !loading,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      PasswordField(
                        controller: _passwordController,
                        enabled: !loading,
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'Masukkan password Anda.'
                            : null,
                        onSubmitted: (_) => _handleLogin(),
                      ),
                      if (auth.state == AuthState.error) ...[
                        const SizedBox(height: AppSpacing.lg),
                        InlineNotice(
                          message: auth.errorMessage,
                          tone: NoticeTone.danger,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      AppButton(
                        label: 'Masuk',
                        loading: loading,
                        onPressed: _handleLogin,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Belum punya akun?',
                            style: theme.textTheme.bodyMedium,
                          ),
                          TextButton(
                            onPressed: loading ? null : _openRegister,
                            child: const Text('Daftar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/models/patient.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../profile/widgets/profile_form.dart';
import '../provider/auth_provider.dart';
import '../widgets/auth_fields.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime? _dateOfBirth;
  String? _gender;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final navigator = Navigator.of(context);
    final phone = _phoneController.text.trim();
    final dob = _dateOfBirth;

    // Field opsional hanya dikirim bila terisi.
    await authProvider.register(
      _emailController.text.trim(),
      _passwordController.text,
      _nameController.text.trim(),
      dateOfBirth: dob == null ? null : toApiDate(dob),
      gender: _gender,
      phoneNumber: phone.isEmpty ? null : phone,
    );
    if (!mounted) return;

    if (authProvider.state == AuthState.authenticated) {
      TextInput.finishAutofillContext();
      // Profil pasien dibuat otomatis oleh backend, langsung ke beranda.
      navigator.pushNamedAndRemoveUntil('/home', (route) => false);
    }
    // Kegagalan ditampilkan sebaris di atas tombol (lihat build).
  }

  void _backToLogin() {
    context.read<AuthProvider>().clearError();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final loading = auth.state == AuthState.loading;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) auth.clearError();
      },
      child: Scaffold(
        appBar: AppBar(),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Buat akun', style: theme.textTheme.headlineMedium),
                    const SizedBox(height: AppSpacing.xs + 2),
                    Text(
                      'Akun diperlukan agar hasil pemeriksaan Anda tersimpan '
                      'dengan aman.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TextFormField(
                      controller: _nameController,
                      enabled: !loading,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      decoration: const InputDecoration(
                        labelText: 'Nama lengkap',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: ProfileForm.validateName,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    EmailField(
                      controller: _emailController,
                      enabled: !loading,
                      isNewAccount: true,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    PasswordField(
                      controller: _passwordController,
                      enabled: !loading,
                      isNewPassword: true,
                      helperText: 'Minimal 8 karakter',
                      textInputAction: TextInputAction.next,
                      validator: (value) => (value == null || value.length < 8)
                          ? 'Password minimal 8 karakter.'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    PasswordField(
                      controller: _confirmPasswordController,
                      label: 'Ulangi password',
                      enabled: !loading,
                      isNewPassword: true,
                      validator: (value) => value != _passwordController.text
                          ? 'Password tidak sama.'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Row(
                      children: [
                        Text('Data diri', style: theme.textTheme.titleLarge),
                        const SizedBox(width: AppSpacing.sm),
                        Text('Opsional', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Bisa dilengkapi nanti di menu Profil.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ProfileForm(
                      phoneController: _phoneController,
                      dateOfBirth: _dateOfBirth,
                      onDateOfBirthChanged: (value) =>
                          setState(() => _dateOfBirth = value),
                      gender: _gender,
                      onGenderChanged: (value) =>
                          setState(() => _gender = value),
                      enabled: !loading,
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
                      label: 'Daftar',
                      loading: loading,
                      onPressed: _handleRegister,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Sudah punya akun?',
                          style: theme.textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: loading ? null : _backToLogin,
                          child: const Text('Masuk'),
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
    );
  }
}

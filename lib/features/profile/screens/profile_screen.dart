import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/errors/exceptions.dart';
import '../../../core/models/patient.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../authentication/provider/auth_provider.dart';
import '../provider/profile_provider.dart';

/// Tab Profil: data diri, edit profil, keluar, dan hapus akun.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _openEdit(BuildContext context, Patient? patient) {
    Navigator.of(context).pushNamed('/edit_profile', arguments: patient);
  }

  /// Keluar hanya setelah konfirmasi, agar tidak terpicu tanpa sengaja.
  Future<void> _confirmLogout(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final navigator = Navigator.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text(
          'Anda perlu masuk kembali untuk melihat riwayat atau melakukan '
          'pemeriksaan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    // Tampilkan indikator selagi token dicabut di server.
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(canPop: false, child: LoadingView()),
    );
    // Menghapus token + seluruh state pengguna (profil, riwayat, jawaban).
    await authProvider.logout();
    navigator.pushNamedAndRemoveUntil('/login', (route) => false);
  }

  /// Alur hapus akun: dialog konfirmasi + password -> DELETE api/account ->
  /// bersihkan sesi -> kembali ke login.
  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final deleted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) =>
          _DeleteAccountDialog(authProvider: authProvider),
    );
    if (deleted != true) return;

    navigator.pushNamedAndRemoveUntil('/login', (route) => false);
    messenger.showSnackBar(
      const SnackBar(content: Text('Akun Anda telah dihapus secara permanen.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    final patient = profile.patient;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: RefreshIndicator(
        onRefresh: profile.loadPatientProfile,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.sm,
            AppSpacing.page,
            AppSpacing.xxl,
          ),
          children: [
            ..._profileSection(context, profile, patient),
            const SizedBox(height: AppSpacing.xl + 4),
            Text('Akun', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _ActionTile(
                    icon: Icons.logout_rounded,
                    label: 'Keluar',
                    onTap: () => _confirmLogout(context),
                  ),
                  const Divider(indent: 60),
                  _ActionTile(
                    icon: Icons.delete_outline_rounded,
                    label: 'Hapus akun',
                    color: AppColors.danger,
                    onTap: () => _confirmDeleteAccount(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Dentist App',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _profileSection(
    BuildContext context,
    ProfileProvider profile,
    Patient? patient,
  ) {
    final theme = Theme.of(context);
    final email = context.watch<AuthProvider>().email;

    if (patient == null) {
      if (profile.error != null) {
        return [
          InlineNotice(
            message: 'Profil belum dapat dimuat: ${profile.error}',
            tone: NoticeTone.danger,
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            onPressed: profile.loadPatientProfile,
            child: const Text('Coba Lagi'),
          ),
        ];
      }
      if (!profile.hasLoaded) {
        return const [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 56),
            child: LoadingView(label: 'Memuat profil…'),
          ),
        ];
      }
      return [
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              const IconBadge(icon: Icons.person_add_alt_1_outlined, size: 60),
              const SizedBox(height: AppSpacing.lg),
              Text('Lengkapi profil Anda', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Profil diperlukan agar hasil pemeriksaan dapat disimpan.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Buat Profil',
                onPressed: () => _openEdit(context, null),
              ),
            ],
          ),
        ),
      ];
    }

    return [
      Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: AppColors.primarySoft,
            child: Text(
              patient.initials,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.name.isEmpty ? 'Tanpa nama' : patient.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall,
                ),
                if (email != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.xl),
      AppCard(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Column(
          children: [
            _InfoRow(
              icon: Icons.cake_outlined,
              label: 'Tanggal lahir',
              value: formatCalendarDateId(patient.dateOfBirth),
            ),
            const Divider(indent: 60),
            _InfoRow(
              icon: Icons.wc_rounded,
              label: 'Jenis kelamin',
              value: patient.genderLabel,
            ),
            const Divider(indent: 60),
            _InfoRow(
              icon: Icons.phone_outlined,
              label: 'Nomor telepon',
              value: patient.phoneNumber ?? '-',
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _openEdit(context, patient),
          icon: const Icon(Icons.edit_outlined, size: 20),
          label: const Text('Edit Profil'),
        ),
      ),
    ];
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.primary),
          const SizedBox(width: AppSpacing.lg + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: AppSpacing.lg + 2),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

/// Dialog konfirmasi hapus akun: penjelasan permanen + input password.
/// Menutup dengan `true` bila akun berhasil dihapus.
class _DeleteAccountDialog extends StatefulWidget {
  final AuthProvider authProvider;

  const _DeleteAccountDialog({required this.authProvider});

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _passwordController = TextEditingController();
  bool _submitting = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _error = 'Masukkan password Anda.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await widget.authProvider.deleteAccount(password);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.statusCode == 422
            ? (e.fieldErrors['password'] ?? 'Password salah.')
            : e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = ApiException.messageOf(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_submitting,
      child: AlertDialog(
        title: const Text('Hapus akun permanen?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Akun, profil, seluruh riwayat pemeriksaan, jawaban, dan foto '
                'Anda akan dihapus permanen. Tindakan ini tidak dapat '
                'dibatalkan.',
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _passwordController,
                obscureText: _obscure,
                enabled: !_submitting,
                autofillHints: const [AutofillHints.password],
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    tooltip: _obscure
                        ? 'Tampilkan password'
                        : 'Sembunyikan password',
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  errorText: _error,
                ),
                onSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _submitting
                ? null
                : () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: const Size(120, 44),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Hapus Akun'),
          ),
        ],
      ),
    );
  }
}

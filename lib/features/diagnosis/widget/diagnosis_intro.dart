import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';

/// Pengantar sebelum pemeriksaan: apa yang akan dilakukan dan apa yang perlu
/// disiapkan (penggaris untuk mengukur bukaan mulut), supaya pengguna tidak
/// terhenti di tengah jalan.
class DiagnosisIntro extends StatelessWidget {
  final bool loading;
  final String? error;
  final VoidCallback onStart;
  final VoidCallback onRetry;

  const DiagnosisIntro({
    super.key,
    required this.loading,
    required this.error,
    required this.onStart,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.sm,
              AppSpacing.page,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Sebelum mulai', style: theme.textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Pemeriksaan ini membantu mengenali tanda gangguan sendi '
                  'rahang (TMD) dalam dua bagian singkat.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                const _StepCard(
                  number: '1',
                  title: 'Pertanyaan gejala',
                  description:
                      'Jawab pertanyaan singkat tentang nyeri, sakit kepala, '
                      'dan gerakan rahang Anda.',
                ),
                const SizedBox(height: AppSpacing.md),
                const _StepCard(
                  number: '2',
                  title: 'Pemeriksaan mandiri',
                  description:
                      'Tekan beberapa titik di wajah, ukur bukaan mulut, dan '
                      'dengarkan bunyi sendi rahang.',
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('Siapkan', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.md),
                const _PrepItem(
                  icon: Icons.straighten_rounded,
                  text: 'Penggaris untuk mengukur bukaan mulut (mm)',
                ),
                const _PrepItem(
                  icon: Icons.volume_up_outlined,
                  text: 'Tempat tenang dan suara ponsel aktif',
                ),
                const _PrepItem(
                  icon: Icons.schedule_rounded,
                  text: 'Waktu sekitar 5 menit',
                ),
                const SizedBox(height: AppSpacing.lg),
                const InlineNotice(
                  message:
                      'Hasilnya adalah skrining awal, bukan pengganti '
                      'pemeriksaan oleh dokter gigi.',
                ),
              ],
            ),
          ),
        ),
        BottomActionBar(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (error != null) ...[
                InlineNotice(message: error!, tone: NoticeTone.danger),
                const SizedBox(height: AppSpacing.md),
              ],
              AppButton(
                label: error != null ? 'Coba Lagi' : 'Mulai Pemeriksaan',
                loading: loading,
                onPressed: error != null ? onRetry : onStart,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  final String number;
  final String title;
  final String description;

  const _StepCard({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(description, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrepItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _PrepItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}

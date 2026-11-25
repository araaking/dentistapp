import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// Kemajuan seluruh pemeriksaan: bagian yang sedang dikerjakan, nomor langkah,
/// dan satu bilah kemajuan yang tidak pernah kembali ke nol di tengah jalan.
class DiagnosisProgressHeader extends StatelessWidget {
  final int sectionNumber;
  final int sectionCount;
  final String sectionTitle;
  final int stepNumber;
  final int totalSteps;
  final double progress;

  const DiagnosisProgressHeader({
    super.key,
    required this.sectionNumber,
    required this.sectionCount,
    required this.sectionTitle,
    required this.stepNumber,
    required this.totalSteps,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.xs,
        AppSpacing.page,
        AppSpacing.md,
      ),
      child: Semantics(
        label:
            'Bagian $sectionNumber dari $sectionCount, $sectionTitle. '
            'Langkah $stepNumber dari $totalSteps.',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'BAGIAN $sectionNumber DARI $sectionCount · '
                    '${sectionTitle.toUpperCase()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  '$stepNumber/$totalSteps',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm + 2),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(end: progress.clamp(0, 1).toDouble()),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                  backgroundColor: AppColors.primarySoft,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

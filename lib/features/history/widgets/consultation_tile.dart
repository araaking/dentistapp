import 'package:material_ui/material_ui.dart';

import '../../../core/models/consultation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/utils/diagnosis_info.dart';
import '../../../core/widgets/app_widgets.dart';

/// Satu baris riwayat pemeriksaan (dipakai di Beranda dan tab Riwayat).
class ConsultationTile extends StatelessWidget {
  final Consultation consultation;
  final VoidCallback onTap;

  const ConsultationTile({
    super.key,
    required this.consultation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final info = DiagnosisInfo.of(consultation.primaryDiagnosis);
    final clear = info.tone == DiagnosisTone.clear;
    final extra = consultation.diagnoses.length - 1;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md + 2,
        AppSpacing.sm,
        AppSpacing.md + 2,
      ),
      child: Row(
        children: [
          IconBadge(
            icon: clear
                ? Icons.check_circle_outline_rounded
                : Icons.monitor_heart_outlined,
            color: clear ? AppColors.success : AppColors.primary,
            background: clear ? AppColors.successSoft : AppColors.primaryTint,
          ),
          const SizedBox(width: AppSpacing.md + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 15.5),
                ),
                const SizedBox(height: 2),
                Text(
                  extra > 0
                      ? '${formatDateId(consultation.date)} · +$extra lainnya'
                      : formatDateId(consultation.date),
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

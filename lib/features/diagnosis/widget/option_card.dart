import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// Satu pilihan jawaban berukuran besar (mudah diketuk dengan ibu jari).
class OptionCard extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Widget tambahan di bawah teks pilihan (mis. tombol contoh suara).
  final Widget? footer;

  const OptionCard({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSpacing.radius);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Semantics(
        inMutuallyExclusiveGroup: true,
        checked: selected,
        button: true,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: selected ? AppColors.primarySoft : AppColors.surface,
            borderRadius: radius,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.8 : 1.2,
            ),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              borderRadius: radius,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 64),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      _RadioDot(selected: selected),
                      const SizedBox(width: AppSpacing.md + 2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 16.5,
                                height: 1.3,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selected
                                    ? AppColors.primaryDark
                                    : AppColors.textPrimary,
                              ),
                            ),
                            if (footer != null) ...[
                              const SizedBox(height: AppSpacing.sm),
                              footer!,
                            ],
                          ],
                        ),
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

class _RadioDot extends StatelessWidget {
  final bool selected;

  const _RadioDot({required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.primary : AppColors.surface,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.textMuted,
          width: 1.8,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
          : null,
    );
  }
}

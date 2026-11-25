import 'dart:io';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../provider/diagnosis_provider.dart';

/// Pengukuran bukaan mulut (mm, wajib) dan foto (opsional) untuk E2.
class EqMeasurementWidget extends StatefulWidget {
  const EqMeasurementWidget({super.key});

  @override
  State<EqMeasurementWidget> createState() => _EqMeasurementWidgetState();
}

class _EqMeasurementWidgetState extends State<EqMeasurementWidget> {
  late final TextEditingController _openingController;

  @override
  void initState() {
    super.initState();
    // Pulihkan nilai yang sudah diketik bila pengguna kembali ke langkah ini.
    final e2 = context
        .read<DiagnosisProvider>()
        .answers[DiagnosisProvider.openingCode];
    final saved = e2 is Map ? e2['opening_mm'] : null;
    _openingController = TextEditingController(text: saved?.toString() ?? '');
  }

  @override
  void dispose() {
    _openingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DiagnosisProvider>();
    final e2 = provider.answers[DiagnosisProvider.openingCode];
    final photo = e2 is Map ? e2['photo'] : null;
    final File? photoFile = photo is File ? photo : null;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Bukaan mulut maksimal', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _openingController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            LengthLimitingTextInputFormatter(5),
          ],
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'Contoh: 40',
            hintStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: AppColors.textMuted,
            ),
            prefixIcon: const Icon(Icons.straighten_rounded),
            suffixText: 'mm',
            suffixStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
            helperText: '1 cm = 10 mm',
            errorText: provider.validationError,
          ),
          onChanged: provider.setOpeningMm,
          onSubmitted: (_) => FocusScope.of(context).unfocus(),
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Text('Foto bukaan mulut', style: theme.textTheme.titleMedium),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: BorderRadius.circular(99),
              ),
              child: const Text(
                'Opsional',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'Ambil foto wajah saat mulut terbuka selebar mungkin.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        if (photoFile == null)
          _PhotoPlaceholder(onTap: provider.takePictureForEQ2)
        else
          _PhotoPreview(
            file: photoFile,
            onRetake: provider.takePictureForEQ2,
            onRemove: provider.removePhoto,
          ),
        if (provider.photoError != null) ...[
          const SizedBox(height: AppSpacing.md),
          InlineNotice(message: provider.photoError!, tone: NoticeTone.danger),
        ],
      ],
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  final VoidCallback onTap;

  const _PhotoPlaceholder({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      color: AppColors.primaryTint,
      borderColor: AppColors.primarySoft,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      child: const Column(
        children: [
          IconBadge(
            icon: Icons.photo_camera_outlined,
            background: AppColors.surface,
            size: 52,
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'Ambil foto',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  final File file;
  final VoidCallback onRetake;
  final VoidCallback onRemove;

  const _PhotoPreview({
    required this.file,
    required this.onRetake,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          child: Image.file(
            file,
            height: 220,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 120,
              color: AppColors.primaryTint,
              alignment: Alignment.center,
              child: const Text('Pratinjau foto tidak tersedia'),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: onRetake,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Ambil ulang'),
              ),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: onRemove,
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                label: const Text('Hapus foto'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

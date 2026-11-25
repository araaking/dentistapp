import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/question_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../provider/diagnosis_provider.dart';
import '../../question_presenter.dart';

/// Pilihan skor nyeri (0-3) per area untuk pertanyaan E1 dan E4.
/// E4 memeriksa area yang sama dengan E1 sehingga memakai gambar yang sama.
class EqPainScoreWidget extends StatelessWidget {
  final QuestionModel question;

  const EqPainScoreWidget({super.key, required this.question});

  static const String _referenceImage = 'assets/images/e1.png';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DiagnosisProvider>();
    final raw = provider.answers[question.code];
    final scores = <String, int>{};
    if (raw is Map) {
      raw.forEach((key, value) {
        if (value is num) scores[key.toString()] = value.toInt();
      });
    }
    final entries = _scoreEntries(question);
    final areas = question.input.areas ?? const <String>[];
    final showMissing = provider.validationError != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _ReferenceImage(asset: _referenceImage),
        const SizedBox(height: AppSpacing.lg),
        for (final area in areas)
          _AreaScoreCard(
            area: area,
            entries: entries,
            selected: scores[area],
            highlightMissing: showMissing && scores[area] == null,
            onSelected: (score) =>
                provider.setAreaScore(question.code, area, score),
          ),
      ],
    );
  }

  /// Skor min..max (default 0..3) beserta label ringkasnya.
  static List<MapEntry<int, String>> _scoreEntries(QuestionModel question) {
    final labels = question.input.labels;
    final min = question.input.min ?? 0;
    final max = question.input.max ?? 3;
    return List.generate(
      max >= min ? max - min + 1 : 0,
      (i) => MapEntry(
        min + i,
        QuestionPresenter.shortScoreLabel(labels?[(min + i).toString()]),
      ),
    );
  }
}

/// Gambar referensi area pemeriksaan; ketuk untuk memperbesar.
class _ReferenceImage extends StatelessWidget {
  final String asset;

  const _ReferenceImage({required this.asset});

  void _openZoom(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            InteractiveViewer(
              maxScale: 4,
              child: Image.asset(asset, fit: BoxFit.contain),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton.filledTonal(
                tooltip: 'Tutup',
                onPressed: () => Navigator.of(dialogContext).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSpacing.radius);
    return Semantics(
      button: true,
      label:
          'Gambar area pemeriksaan: pelipis, pipi, dan sendi rahang. '
          'Ketuk untuk memperbesar.',
      excludeSemantics: true,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openZoom(context),
          child: Stack(
            children: [
              SizedBox(
                height: 210,
                width: double.infinity,
                child: Image.asset(
                  asset,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Text('Gambar referensi tidak tersedia'),
                  ),
                ),
              ),
              Positioned(
                right: AppSpacing.sm,
                bottom: AppSpacing.sm,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.zoom_in_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Perbesar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AreaScoreCard extends StatelessWidget {
  final String area;
  final List<MapEntry<int, String>> entries;
  final int? selected;
  final bool highlightMissing;
  final ValueChanged<int> onSelected;

  const _AreaScoreCard({
    required this.area,
    required this.entries,
    required this.selected,
    required this.highlightMissing,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final hint = QuestionPresenter.areaHint(area);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        border: Border.all(
          color: highlightMissing ? AppColors.danger : AppColors.border,
          width: highlightMissing ? 1.6 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  QuestionPresenter.areaLabel(area),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (selected != null)
                const Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: AppColors.success,
                ),
            ],
          ),
          if (hint != null) ...[
            const SizedBox(height: 2),
            Text(hint, style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              for (var i = 0; i < entries.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _ScoreButton(
                    score: entries[i].key,
                    label: entries[i].value,
                    selected: selected == entries[i].key,
                    onTap: () => onSelected(entries[i].key),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreButton extends StatelessWidget {
  final int score;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ScoreButton({
    required this.score,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSpacing.radiusSm);
    final foreground = selected ? Colors.white : AppColors.textPrimary;
    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      checked: selected,
      label: label.isEmpty ? 'Skor $score' : 'Skor $score, $label',
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.background,
          borderRadius: radius,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: 1.2,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 60),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$score',
                      style: TextStyle(
                        fontSize: 19,
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                        color: foreground,
                      ),
                    ),
                    if (label.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.1,
                          fontWeight: FontWeight.w500,
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
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

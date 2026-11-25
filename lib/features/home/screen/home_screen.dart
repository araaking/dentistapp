import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/models/consultation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../history/provider/history_provider.dart';
import '../../history/widgets/consultation_tile.dart';
import '../../profile/provider/profile_provider.dart';

/// Tab Beranda: satu aksi utama (mulai pemeriksaan) dan ringkasan riwayat.
class HomeScreen extends StatelessWidget {
  final VoidCallback onStartDiagnosis;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenProfile;
  final Future<void> Function() onRefresh;

  const HomeScreen({
    super.key,
    required this.onStartDiagnosis,
    required this.onOpenHistory,
    required this.onOpenProfile,
    required this.onRefresh,
  });

  /// Jumlah riwayat terbaru yang ditampilkan di Beranda.
  static const int _recentCount = 3;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.overlayStyle,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.lg,
                AppSpacing.page,
                AppSpacing.xxl,
              ),
              children: [
                _Header(onOpenProfile: onOpenProfile),
                const SizedBox(height: AppSpacing.xl),
                _StartCard(onStart: onStartDiagnosis),
                const SizedBox(height: AppSpacing.xl + 4),
                _RecentHistory(
                  onOpenHistory: onOpenHistory,
                  onOpen: (consultation) => Navigator.of(context)
                      .pushNamed('/diagnosis_result', arguments: consultation),
                ),
                const SizedBox(height: AppSpacing.xl + 4),
                const _AboutTmdCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onOpenProfile;

  const _Header({required this.onOpenProfile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final patient = context.watch<ProfileProvider>().patient;
    final name = patient?.firstName ?? '';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isEmpty ? 'Halo!' : 'Halo, $name',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 2),
              Text(
                'Bagaimana kondisi rahang Anda?',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Semantics(
          button: true,
          label: 'Buka profil',
          excludeSemantics: true,
          child: InkResponse(
            onTap: onOpenProfile,
            radius: 30,
            child: CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primarySoft,
              child: Text(
                patient?.initials ?? '?',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StartCard extends StatelessWidget {
  final VoidCallback onStart;

  const _StartCard({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB8647A), AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -14,
            child: SizedBox(
              width: 130,
              height: 130,
              child: CustomPaint(
                painter: ToothPainter(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Periksa sendi rahang Anda',
                  style: TextStyle(
                    fontSize: 21,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Jawab pertanyaan singkat dan lakukan pemeriksaan mandiri '
                  'untuk skrining gangguan sendi rahang (TMD).',
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.45,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const Row(
                  children: [
                    _MetaChip(icon: Icons.schedule_rounded, label: '± 5 menit'),
                    SizedBox(width: AppSpacing.sm),
                    _MetaChip(icon: Icons.checklist_rounded, label: '2 bagian'),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg + 2),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onStart,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primaryDark,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Mulai Pemeriksaan'),
                        SizedBox(width: AppSpacing.sm),
                        Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
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

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentHistory extends StatelessWidget {
  final VoidCallback onOpenHistory;
  final ValueChanged<Consultation> onOpen;

  const _RecentHistory({required this.onOpenHistory, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryProvider>();
    final items = history.items;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Pemeriksaan terakhir',
          actionLabel: items.length > HomeScreen._recentCount
              ? 'Lihat semua'
              : null,
          onAction: onOpenHistory,
        ),
        const SizedBox(height: AppSpacing.md),
        if (items.isNotEmpty)
          for (final consultation in items.take(HomeScreen._recentCount))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: ConsultationTile(
                consultation: consultation,
                onTap: () => onOpen(consultation),
              ),
            )
        else if (history.error != null)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Riwayat belum dapat dimuat',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  history.error!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: history.load,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                    ),
                    child: const Text('Coba Lagi'),
                  ),
                ),
              ],
            ),
          )
        else if (!history.hasLoaded)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: LoadingView(),
          )
        else
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg + 2),
            child: Row(
              children: [
                const IconBadge(icon: Icons.history_rounded),
                const SizedBox(width: AppSpacing.md + 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Belum ada pemeriksaan',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Hasil pemeriksaan pertama Anda akan muncul di sini.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AboutTmdCard extends StatelessWidget {
  const _AboutTmdCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      color: AppColors.primaryTint,
      borderColor: AppColors.primarySoft,
      padding: const EdgeInsets.all(AppSpacing.lg + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                size: 20,
                color: AppColors.primaryDark,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('Apa itu TMD?', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'TMD (temporomandibular disorder) adalah gangguan pada sendi '
            'rahang dan otot pengunyah. Tandanya antara lain nyeri di rahang '
            'atau pelipis, bunyi "klik" saat membuka mulut, dan rahang terasa '
            'terkunci.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

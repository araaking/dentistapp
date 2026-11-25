import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/models/consultation.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../provider/history_provider.dart';
import '../widgets/consultation_tile.dart';

/// Tab Riwayat: seluruh hasil pemeriksaan, terbaru di atas.
class HistoryScreen extends StatelessWidget {
  /// Dipanggil saat pengguna menekan "Mulai Pemeriksaan" di keadaan kosong.
  final VoidCallback onStartDiagnosis;

  const HistoryScreen({super.key, required this.onStartDiagnosis});

  void _open(BuildContext context, Consultation consultation) {
    Navigator.of(context)
        .pushNamed('/diagnosis_result', arguments: consultation);
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat')),
      body: _buildBody(context, history),
    );
  }

  Widget _buildBody(BuildContext context, HistoryProvider history) {
    final items = history.items;

    if (items.isEmpty) {
      if (history.error != null) {
        return StateView.error(
          title: 'Riwayat belum dapat dimuat',
          message: history.error!,
          onAction: history.load,
        );
      }
      if (!history.hasLoaded) return const LoadingView();
      return StateView(
        icon: Icons.history_rounded,
        title: 'Belum ada riwayat',
        message: 'Hasil pemeriksaan Anda akan tersimpan di sini.',
        actionLabel: 'Mulai Pemeriksaan',
        onAction: onStartDiagnosis,
      );
    }

    return RefreshIndicator(
      onRefresh: history.load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.sm,
          AppSpacing.page,
          AppSpacing.xl,
        ),
        itemCount: items.length + (history.error != null ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          if (history.error != null) {
            if (index == 0) {
              return InlineNotice(
                message: 'Gagal memperbarui riwayat: ${history.error}',
                tone: NoticeTone.warning,
              );
            }
            index -= 1;
          }
          final consultation = items[index];
          return ConsultationTile(
            consultation: consultation,
            onTap: () => _open(context, consultation),
          );
        },
      ),
    );
  }
}

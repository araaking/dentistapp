import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/models/consultation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/utils/diagnosis_info.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../authentication/provider/auth_provider.dart';
import '../provider/diagnosis_provider.dart';

/// Menampilkan hasil pemeriksaan.
///
/// - Pemeriksaan baru ([consultation] null): pengiriman dimiliki oleh
///   [DiagnosisProvider.submitConsultation] (hanya sekali); layar ini hanya
///   memicu dan mengamati statusnya.
/// - Dari riwayat: menampilkan [consultation] yang diberikan.
class DiagnosisResultScreen extends StatefulWidget {
  final Consultation? consultation;

  const DiagnosisResultScreen({super.key, this.consultation});

  @override
  State<DiagnosisResultScreen> createState() => _DiagnosisResultScreenState();
}

class _DiagnosisResultScreenState extends State<DiagnosisResultScreen> {
  late final DiagnosisProvider _provider;

  bool get _isNewResult => widget.consultation == null;

  @override
  void initState() {
    super.initState();
    _provider = context.read<DiagnosisProvider>();
    if (_isNewResult) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _provider.submitConsultation();
      });
    }
  }

  @override
  void dispose() {
    if (_isNewResult) {
      // Jawaban kesehatan tidak perlu tinggal di memori setelah hasil ditutup.
      final provider = _provider;
      Future.microtask(provider.resetDiagnosis);
    }
    super.dispose();
  }

  void _close() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushNamedAndRemoveUntil('/home', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = widget.consultation;
    if (history != null) {
      return _scaffold(
        canPop: true,
        body: _ResultContent(
          consultation: history,
          closeLabel: 'Kembali',
          onClose: _close,
        ),
      );
    }

    final provider = context.watch<DiagnosisProvider>();
    final submitting =
        provider.submissionState == SubmissionState.idle ||
        provider.submissionState == SubmissionState.submitting;

    final Widget body;
    switch (provider.submissionState) {
      case SubmissionState.idle:
      case SubmissionState.submitting:
        body = const LoadingView(label: 'Menganalisis jawaban Anda…');
      case SubmissionState.error:
        body = _SubmissionError(
          message: provider.submissionError,
          onRetry: provider.submitConsultation,
          onClose: _close,
        );
      case SubmissionState.success:
        body = _ResultContent(
          consultation: provider.submissionResult ?? const Consultation(),
          closeLabel: 'Kembali ke Beranda',
          onClose: _close,
        );
    }

    // Saat mengirim, tombol kembali dikunci agar hasil tidak terlewat.
    return _scaffold(canPop: !submitting, body: body);
  }

  Widget _scaffold({required bool canPop, required Widget body}) {
    return PopScope(
      canPop: canPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Hasil Pemeriksaan'),
          automaticallyImplyLeading: false,
          leading: canPop
              ? IconButton(
                  tooltip: 'Tutup',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: _close,
                )
              : null,
        ),
        body: body,
      ),
    );
  }
}

class _ResultContent extends StatelessWidget {
  final Consultation consultation;
  final String closeLabel;
  final VoidCallback onClose;

  const _ResultContent({
    required this.consultation,
    required this.closeLabel,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final names = consultation.diagnoses.isEmpty
        ? const <String?>[null]
        : consultation.diagnoses;
    final infos = names.map(DiagnosisInfo.of).toList();
    final needsAttention = infos.any(
      (info) => info.tone == DiagnosisTone.attention,
    );
    final photoUrl = consultation.photoUrl;

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
                if (consultation.date != null) ...[
                  Text(
                    'Diperiksa ${formatDateTimeId(consultation.date)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                for (final info in infos) ...[
                  _DiagnosisCard(info: info),
                  const SizedBox(height: AppSpacing.md),
                ],
                const SizedBox(height: AppSpacing.sm),
                Text('Langkah selanjutnya', style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  child: Column(
                    children: needsAttention
                        ? const [
                            _NextStep(
                              icon: Icons.medical_services_outlined,
                              text:
                                  'Periksakan diri ke dokter gigi untuk '
                                  'pemeriksaan lebih lanjut.',
                            ),
                            SizedBox(height: AppSpacing.md),
                            _NextStep(
                              icon: Icons.history_rounded,
                              text:
                                  'Tunjukkan hasil ini saat konsultasi. '
                                  'Hasil tersimpan di menu Riwayat.',
                            ),
                          ]
                        : const [
                            _NextStep(
                              icon: Icons.event_repeat_outlined,
                              text:
                                  'Ulangi pemeriksaan bila keluhan muncul '
                                  'atau berubah.',
                            ),
                            SizedBox(height: AppSpacing.md),
                            _NextStep(
                              icon: Icons.medical_services_outlined,
                              text:
                                  'Tetap konsultasikan ke dokter gigi bila '
                                  'Anda merasakan nyeri atau rahang sulit '
                                  'digerakkan.',
                            ),
                          ],
                  ),
                ),
                if (photoUrl != null) ...[
                  const SizedBox(height: AppSpacing.xl),
                  Text('Foto bukaan mulut', style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.md),
                  _ConsultationPhoto(url: photoUrl),
                ],
                const SizedBox(height: AppSpacing.xl),
                const InlineNotice(
                  message:
                      'Hasil ini adalah skrining awal berdasarkan jawaban '
                      'Anda, bukan diagnosis medis. Hanya dokter gigi yang '
                      'dapat memastikan kondisi Anda.',
                ),
              ],
            ),
          ),
        ),
        BottomActionBar(
          child: AppButton(label: closeLabel, onPressed: onClose),
        ),
      ],
    );
  }
}

class _DiagnosisCard extends StatelessWidget {
  final DiagnosisInfo info;

  const _DiagnosisCard({required this.info});

  @override
  Widget build(BuildContext context) {
    final clear = info.tone == DiagnosisTone.clear;
    final accent = clear ? AppColors.success : AppColors.primaryDark;
    final background = clear ? AppColors.successSoft : AppColors.primarySoft;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(
            icon: clear
                ? Icons.check_circle_outline_rounded
                : Icons.monitor_heart_outlined,
            color: accent,
            background: AppColors.surface,
            size: 52,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            clear ? 'HASIL SKRINING' : 'KEMUNGKINAN KONDISI',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              color: accent,
            ),
          ),
          const SizedBox(height: AppSpacing.xs + 2),
          Text(info.title, style: Theme.of(context).textTheme.headlineSmall),
          if (info.medicalTerm != null) ...[
            const SizedBox(height: 2),
            Text(
              info.medicalTerm!,
              style: const TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            info.description,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _NextStep extends StatelessWidget {
  final IconData icon;
  final String text;

  const _NextStep({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: AppColors.primary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(fontSize: 15),
          ),
        ),
      ],
    );
  }
}

/// Foto konsultasi: URL privat, wajib memakai header Authorization.
class _ConsultationPhoto extends StatelessWidget {
  final String url;

  const _ConsultationPhoto({required this.url});

  static const double _height = 220;

  @override
  Widget build(BuildContext context) {
    final token = context.read<AuthProvider>().token;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radius),
      child: Image.network(
        url,
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
        height: _height,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            height: _height,
            color: AppColors.primaryTint,
            child: const LoadingView(),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: _height,
            color: AppColors.primaryTint,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.textMuted,
                  size: 36,
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'Foto tidak dapat dimuat',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SubmissionError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  const _SubmissionError({
    required this.message,
    required this.onRetry,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StateView(
            icon: Icons.cloud_off_rounded,
            isError: true,
            title: 'Jawaban belum terkirim',
            message:
                '$message\n\nJawaban Anda masih tersimpan di perangkat '
                'ini. Coba kirim lagi.',
          ),
        ),
        BottomActionBar(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppButton(label: 'Kirim Ulang', onPressed: onRetry),
              const SizedBox(height: AppSpacing.xs),
              TextButton(
                onPressed: onClose,
                child: const Text('Batalkan dan Keluar'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/models/question_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../provider/diagnosis_provider.dart';
import '../question_presenter.dart';
import '../widget/diagnosis_intro.dart';
import '../widget/diagnosis_progress_header.dart';
import '../widget/question_content_builder.dart';

/// Alur pemeriksaan mandiri: pengantar -> pertanyaan gejala -> pemeriksaan
/// mandiri -> konfirmasi kirim. Hasil ditampilkan di `/diagnosis_result`.
class QuestionScreen extends StatefulWidget {
  const QuestionScreen({super.key});

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  /// Jeda sebelum otomatis lanjut, agar pengguna sempat melihat pilihannya.
  static const Duration _autoAdvanceDelay = Duration(milliseconds: 260);

  late final DiagnosisProvider _provider;
  bool _started = false; // false = masih di layar pengantar
  bool _navigatedToResult = false;
  Timer? _autoAdvance;

  @override
  void initState() {
    super.initState();
    _provider = context.read<DiagnosisProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Selalu mulai dari keadaan bersih, lalu muat pertanyaan selagi
      // pengguna membaca pengantar.
      _provider
        ..resetDiagnosis()
        ..fetchQuestions();
    });
  }

  @override
  void dispose() {
    _autoAdvance?.cancel();
    if (!_navigatedToResult) {
      // Keluar di tengah jalan: buang jawaban dan foto sementara. Ditunda
      // agar tidak memicu notifyListeners saat pohon widget sedang dibongkar.
      final provider = _provider;
      Future.microtask(provider.resetDiagnosis);
    }
    super.dispose();
  }

  // --- Navigasi langkah ---
  Future<void> _next() async {
    _autoAdvance?.cancel();
    FocusManager.instance.primaryFocus?.unfocus();
    final provider = _provider;

    if (!provider.isLastStep) {
      provider.nextQuestion();
      return;
    }

    // Langkah terakhir: validasi dulu, lalu minta konfirmasi sebelum kirim.
    if (provider.validateCurrentQuestion() != null) {
      provider.nextQuestion(); // memunculkan pesan validasi
      return;
    }
    final confirmed = await _confirmSubmit();
    if (confirmed != true || !mounted) return;
    if (provider.nextQuestion() && provider.stage == DiagnosisStage.finished) {
      _navigatedToResult = true;
      // Pengiriman dimulai & dimiliki oleh halaman hasil lewat
      // DiagnosisProvider.submitConsultation().
      Navigator.of(context).pushReplacementNamed('/diagnosis_result');
    }
  }

  void _back() {
    _autoAdvance?.cancel();
    FocusManager.instance.primaryFocus?.unfocus();
    _provider.previousQuestion();
  }

  /// Pertanyaan gejala dijawab dengan satu ketukan, jadi langsung lanjut.
  /// Di akhir bagian pengguna menekan "Lanjut" sendiri, sebagai jeda sebelum
  /// masuk ke pemeriksaan mandiri.
  void _scheduleAutoAdvance(QuestionModel question) {
    _autoAdvance?.cancel();
    if (_provider.stage != DiagnosisStage.sq || _provider.isLastStepOfSection) {
      return;
    }
    _autoAdvance = Timer(_autoAdvanceDelay, () {
      if (!mounted) return;
      if (_provider.currentQuestion?.code == question.code) {
        _provider.nextQuestion();
      }
    });
  }

  // --- Keluar ---
  Future<void> _requestExit() async {
    _autoAdvance?.cancel();
    final navigator = Navigator.of(context);
    if (!_started || !_provider.hasProgress) {
      navigator.pop();
      return;
    }
    final exit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar dari pemeriksaan?'),
        content: const Text(
          'Jawaban yang sudah diisi tidak disimpan dan Anda perlu mengulang '
          'dari awal.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Lanjutkan Pemeriksaan'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (exit == true && mounted) navigator.pop();
  }

  void _handleSystemBack() {
    if (_started && _provider.canGoBack) {
      _back();
    } else {
      _requestExit();
    }
  }

  Future<bool?> _confirmSubmit() {
    return showModalBottomSheet<bool>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: IconBadge(icon: Icons.fact_check_outlined, size: 52),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Kirim jawaban Anda?',
                style: Theme.of(sheetContext).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Semua langkah sudah terisi. Setelah dikirim, jawaban tidak '
                'dapat diubah dan hasilnya tersimpan di riwayat Anda.',
                style: Theme.of(sheetContext).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Kirim & Lihat Hasil',
                onPressed: () => Navigator.of(sheetContext).pop(true),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(false),
                child: const Text('Periksa Lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DiagnosisProvider>();
    final blocksPop = _started && (provider.canGoBack || provider.hasProgress);

    return PopScope(
      canPop: !blocksPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleSystemBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pemeriksaan Mandiri'),
          leading: IconButton(
            tooltip: 'Tutup',
            icon: const Icon(Icons.close_rounded),
            onPressed: _requestExit,
          ),
        ),
        body: _buildBody(provider),
      ),
    );
  }

  Widget _buildBody(DiagnosisProvider provider) {
    if (!_started) {
      return DiagnosisIntro(
        loading:
            provider.state == DiagnosisState.initial ||
            provider.state == DiagnosisState.loading,
        error: provider.state == DiagnosisState.error
            ? provider.errorMessage
            : null,
        onRetry: provider.fetchQuestions,
        onStart: () => setState(() => _started = true),
      );
    }

    final question = provider.currentQuestion;
    if (provider.state == DiagnosisState.error) {
      return StateView.error(
        message: provider.errorMessage,
        onAction: provider.fetchQuestions,
      );
    }
    if (provider.state != DiagnosisState.loaded || question == null) {
      return const LoadingView();
    }

    return Column(
      children: [
        DiagnosisProgressHeader(
          sectionNumber: provider.sectionNumber,
          sectionCount: provider.sectionCount,
          sectionTitle: QuestionPresenter.sectionTitle(provider.sectionNumber),
          stepNumber: provider.stepNumber,
          totalSteps: provider.totalSteps,
          progress: provider.progress,
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            // Rata atas: posisi judul tetap sama di setiap langkah.
            layoutBuilder: (currentChild, previousChildren) => Stack(
              alignment: Alignment.topCenter,
              children: [...previousChildren, ?currentChild],
            ),
            child: _QuestionPage(
              // Key per pertanyaan: posisi gulir dan state input di-reset.
              key: ValueKey(question.code),
              question: question,
              onChoiceSelected: (_) => _scheduleAutoAdvance(question),
            ),
          ),
        ),
        BottomActionBar(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pesan validasi selalu terlihat, di mana pun posisi gulir.
              // (E2 menampilkannya langsung di kolom input.)
              if (provider.validationError != null &&
                  question.input.type != 'composite') ...[
                InlineNotice(
                  message: provider.validationError!,
                  tone: NoticeTone.danger,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              Row(
                children: [
                  if (provider.canGoBack) ...[
                    OutlinedButton(
                      onPressed: _back,
                      child: const Text('Kembali'),
                    ),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  Expanded(
                    child: AppButton(
                      label: provider.isLastStep ? 'Selesai' : 'Lanjut',
                      icon: provider.isLastStep
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                      onPressed: _next,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Satu langkah: judul, petunjuk, dan input.
class _QuestionPage extends StatelessWidget {
  final QuestionModel question;
  final ValueChanged<String> onChoiceSelected;

  const _QuestionPage({
    super.key,
    required this.question,
    required this.onChoiceSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final instruction = QuestionPresenter.instruction(question);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.lg,
        AppSpacing.page,
        AppSpacing.xl,
      ),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              QuestionPresenter.title(question),
              style: theme.textTheme.headlineSmall,
            ),
          ),
          if (instruction != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              instruction,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          QuestionContentBuilder(
            question: question,
            onChoiceSelected: onChoiceSelected,
          ),
        ],
      ),
    );
  }
}

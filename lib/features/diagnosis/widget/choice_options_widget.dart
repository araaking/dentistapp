import 'package:audioplayers/audioplayers.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/models/question_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/constants.dart';
import '../provider/diagnosis_provider.dart';
import '../question_presenter.dart';
import 'option_card.dart';

/// Satu opsi jawaban: nilai yang dikirim ke server, teks tampilan, dan contoh
/// suara opsional.
class ChoiceOption {
  final String value;
  final String label;
  final String? audio;

  const ChoiceOption({required this.value, required this.label, this.audio});

  /// Opsi dari API berupa string (`"Ya"`) atau map (`{value, label, audio}`).
  static List<ChoiceOption> listFrom(QuestionModel question) {
    final result = <ChoiceOption>[];
    for (final raw in question.input.options ?? const []) {
      if (raw is Map) {
        final value = raw['value']?.toString() ?? '';
        if (value.isEmpty) continue;
        final label = raw['label']?.toString();
        final audio = raw['audio']?.toString();
        result.add(
          ChoiceOption(
            value: value,
            label: (label == null || label.isEmpty)
                ? QuestionPresenter.optionLabel(question.code, value)
                : label,
            audio: (audio == null || audio.isEmpty) ? null : audio,
          ),
        );
      } else if (raw != null && raw.toString().isNotEmpty) {
        final value = raw.toString();
        result.add(
          ChoiceOption(
            value: value,
            label: QuestionPresenter.optionLabel(question.code, value),
          ),
        );
      }
    }
    return result;
  }
}

/// Daftar pilihan tunggal (tipe `radio` dan `select`), dengan tombol contoh
/// suara untuk opsi yang memilikinya (E3).
class ChoiceOptionsWidget extends StatefulWidget {
  final QuestionModel question;

  /// Dipanggil setelah pengguna memilih sebuah opsi.
  final ValueChanged<String>? onSelected;

  const ChoiceOptionsWidget({
    super.key,
    required this.question,
    this.onSelected,
  });

  @override
  State<ChoiceOptionsWidget> createState() => _ChoiceOptionsWidgetState();
}

class _ChoiceOptionsWidgetState extends State<ChoiceOptionsWidget> {
  /// Contoh suara yang dibundel bersama aplikasi (kunci = nama file).
  static const Map<String, String> _bundledSounds = {
    'kliktunggaldanganda.wav': 'sounds/kliktunggaldanganda.wav',
    'krepitasi.wav': 'sounds/krepitasi.wav',
  };

  AudioPlayer? _player; // dibuat hanya bila ada suara yang diputar
  String? _playingValue;

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  /// Menentukan sumber suara. Aset bawaan diutamakan (cepat, bisa offline).
  /// URL dari server hanya diputar lewat HTTPS dan selalu diarahkan ke host
  /// API yang dikonfigurasi, tidak pernah ke host lain.
  static Source? resolveSource(String audio) {
    final fileName = audio.split(RegExp(r'[/\\]')).last.toLowerCase();
    final bundled = _bundledSounds[fileName];
    if (bundled != null) return AssetSource(bundled);

    final uri = Uri.tryParse(audio);
    if (uri == null || !uri.hasScheme) return null;
    final resolved = Uri.tryParse(AppConstants.resolveApiUrl(audio));
    if (resolved == null || resolved.scheme != 'https') return null;
    return UrlSource(resolved.toString());
  }

  Future<void> _toggle(ChoiceOption option) async {
    final audio = option.audio;
    if (audio == null) return;

    if (_playingValue == option.value) {
      await _player?.stop();
      if (mounted) setState(() => _playingValue = null);
      return;
    }

    final source = resolveSource(audio);
    if (source == null) {
      _showPlaybackError();
      return;
    }

    try {
      final player = _player ??= AudioPlayer()
        ..onPlayerComplete.listen((_) {
          if (mounted) setState(() => _playingValue = null);
        });
      await player.stop();
      if (!mounted) return;
      setState(() => _playingValue = option.value);
      await player.play(source);
    } catch (_) {
      if (!mounted) return;
      setState(() => _playingValue = null);
      _showPlaybackError();
    }
  }

  void _showPlaybackError() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Contoh suara tidak dapat diputar.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DiagnosisProvider>();
    final code = widget.question.code;
    final selected = provider.answers[code]?.toString();
    final options = ChoiceOption.listFrom(widget.question);

    if (options.isEmpty) {
      return const Text('Pilihan jawaban tidak tersedia.');
    }

    return Column(
      children: [
        for (final option in options)
          OptionCard(
            label: option.label,
            selected: selected == option.value,
            onTap: () {
              provider.answerQuestion(code, option.value);
              widget.onSelected?.call(option.value);
            },
            footer: option.audio == null
                ? null
                : _SoundButton(
                    playing: _playingValue == option.value,
                    onPressed: () => _toggle(option),
                  ),
          ),
      ],
    );
  }
}

class _SoundButton extends StatelessWidget {
  final bool playing;
  final VoidCallback onPressed;

  const _SoundButton({required this.playing, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelLarge
        ?.copyWith(fontSize: 13.5, fontWeight: FontWeight.w600);
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryDark,
        backgroundColor: playing ? AppColors.surface : AppColors.primaryTint,
        padding: const EdgeInsets.fromLTRB(10, 0, 14, 0),
        minimumSize: const Size(48, 40),
        tapTargetSize: MaterialTapTargetSize.padded,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: labelStyle,
      ),
      icon: Icon(
        playing ? Icons.stop_rounded : Icons.volume_up_rounded,
        size: 20,
      ),
      label: Text(playing ? 'Hentikan' : 'Dengar contoh'),
    );
  }
}

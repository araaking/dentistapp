import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../core/models/question_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../provider/diagnosis_provider.dart';

class EqAudioOptionWidget extends StatefulWidget {
  final QuestionModel question;
  const EqAudioOptionWidget({super.key, required this.question});

  @override
  State<EqAudioOptionWidget> createState() => _EqAudioOptionWidgetState();
}

class _EqAudioOptionWidgetState extends State<EqAudioOptionWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playAudio(String? source, String label) async {
    if (source == null || source.isEmpty) {
      // Fallback mapping berdasarkan label
      final lower = label.toLowerCase();
      if (lower.contains('krep')) {
        source = 'assets/sounds/krepitasi.wav';
      } else if (lower.contains('klik')) {
        source = 'assets/sounds/kliktunggaldanganda.wav';
      }
    }
    if (source == null || source.isEmpty) return;
    try {
      if (source.startsWith('http')) {
        await _audioPlayer.play(UrlSource(source));
      } else {
        // Asumsikan path asset
        // Hilangkan prefix jika perlu
        final assetPath = source.startsWith('assets/') ? source.substring('assets/'.length) : source;
        await _audioPlayer.play(AssetSource(assetPath));
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error playing audio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DiagnosisProvider>();
    final selectedAnswer = provider.answers[widget.question.code];

    return Column(
      children: (widget.question.input.options ?? []).map((optionData) {
        if (optionData is! Map) return const SizedBox.shrink();
        final map = Map<String, dynamic>.from(optionData as Map);
        final value = map['value']?.toString() ?? '';
        final label = map['label']?.toString() ?? value;
        final audioSrc = map['audio']?.toString();
        final isSelected = selectedAnswer == value;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: InkWell(
            onTap: () {
              provider.answerQuestion(widget.question.code, value);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: isSelected ? AppColors.primary : Colors.grey.shade400,
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
                  if (audioSrc != null || label.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.volume_up, color: AppColors.primary),
                      onPressed: () => _playAudio(audioSrc, label),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

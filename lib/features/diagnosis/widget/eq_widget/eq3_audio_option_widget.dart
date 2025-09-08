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
    print('=== DEBUG: Attempting to play audio ===');
    print('Source: $source');
    print('Label: $label');
    
    if (source == null || source.isEmpty) {
      print('=== DEBUG: Source is null/empty, using fallback ===');
      // Fallback mapping berdasarkan label
      final lower = label.toLowerCase();
      if (lower.contains('krep')) {
        source = 'sounds/krepitasi.wav';
      } else if (lower.contains('klik')) {
        source = 'sounds/kliktunggaldanganda.wav';
      }
      print('=== DEBUG: Fallback source: $source ===');
    }
    
    if (source == null || source.isEmpty) {
      print('=== DEBUG: No audio source available ===');
      return;
    }
    
    try {
      print('=== DEBUG: Playing audio from: $source ===');
      if (source.startsWith('http')) {
        print('=== DEBUG: Playing from URL ===');
        await _audioPlayer.play(UrlSource(source));
      } else if (source.startsWith('assets/')) {
        print('=== DEBUG: Playing from asset (with assets/ prefix) ===');
        final assetPath = source.substring('assets/'.length);
        await _audioPlayer.play(AssetSource(assetPath));
      } else {
        print('=== DEBUG: Playing from asset (without assets/ prefix) ===');
        await _audioPlayer.play(AssetSource(source));
      }
      print('=== DEBUG: Audio playback started ===');
    } catch (e) {
      print('=== DEBUG: Error playing audio: $e ===');
      print('=== DEBUG: Stack trace: ${e.toString()} ===');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DiagnosisProvider>();
    final selectedAnswer = provider.answers[widget.question.code];
    
    print('=== DEBUG: Building EqAudioOptionWidget ===');
    print('Question code: ${widget.question.code}');
    print('Selected answer: $selectedAnswer');
    print('Options: ${widget.question.input.options}');

    return Column(
      children: (widget.question.input.options ?? []).map((optionData) {
        if (optionData is! Map) return const SizedBox.shrink();
        final map = Map<String, dynamic>.from(optionData);
        final value = map['value']?.toString() ?? '';
        final label = map['label']?.toString() ?? value;
        final audioSrc = map['audio']?.toString();
        
        print('=== DEBUG: Option ===');
        print('Value: $value');
        print('Label: $label');
        print('Audio source: $audioSrc');

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

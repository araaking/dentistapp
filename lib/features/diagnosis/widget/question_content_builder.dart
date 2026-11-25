import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/question_model.dart';
import '../provider/diagnosis_provider.dart';
import 'answer_option_widget.dart';
import 'eq_widget/eq_pain_score_widget.dart';
import 'eq_widget/eq2_measurement_widget.dart';
import 'eq_widget/eq3_audio_option_widget.dart';

class QuestionContentBuilder extends StatelessWidget {
  final QuestionModel question;

  const QuestionContentBuilder({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    final inputType = question.input.type;

    switch (inputType) {
      case 'radio':
        // Cek jika ada audio; jika ya, gunakan widget audio khusus
        final hasAudio = (question.input.options ?? [])
            .any((opt) => opt is Map && opt.containsKey('audio'));
        if (hasAudio) {
          return EqAudioOptionWidget(question: question);
        }
        return Builder(builder: (context) {
          final provider = context.watch<DiagnosisProvider>();
          final selected = provider.answers[question.code];
          final options = (question.input.options ?? [])
              .map((opt) => opt.toString())
              .toList();
          return Column(
            children: options.map((option) {
              final isSelected = selected == option;
              return AnswerOption(
                text: option,
                isSelected: isSelected,
                onTap: () {
                  provider.answerQuestion(question.code, option);
                },
              );
            }).toList(),
          );
        });

      case 'group_select_scores': // E1 dan E4
        return EqPainScoreWidget(question: question);

      case 'composite': // E2
        return EqMeasurementWidget(question: question);

      case 'select':
        return Builder(builder: (context) {
          final provider = context.watch<DiagnosisProvider>();
          final selected = provider.answers[question.code]?.toString();
          final options = (question.input.options ?? [])
              .map((opt) => opt.toString())
              .toList();

          return DropdownButtonFormField<String>(
            value: options.contains(selected) ? selected : null,
            items: options.map((option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                provider.answerQuestion(question.code, value);
              }
            },
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Pilih jawaban',
            ),
          );
        });

      default:
        return const Text('Tipe pertanyaan ini tidak didukung.');
    }
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/question_model.dart';
import '../provider/diagnosis_provider.dart';
import 'answer_option_widget.dart';
import 'eq_widget/eq1_pain_score_widget.dart';
import 'eq_widget/eq4_pain_score_widget.dart';
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

      case 'group_select_scores':
        // Distinguish EQ1 vs EQ4 by exact question code
        switch (question.code) {
          case 'E4':
          case 'EQ4':
            return Eq4PainScoreWidget(question: question);
          case 'E1':
          case 'EQ1':
            return EqPainScoreWidget(question: question);
          default:
            // Fallback untuk kode lain yang tidak dikenali
            return EqPainScoreWidget(question: question);
        }
      
      case 'composite': // For EQ2
        return EqMeasurementWidget(question: question);
      case 'select':
        return Builder(builder: (context) {
          final provider = context.watch<DiagnosisProvider>();
          final selected = provider.answers[question.code];
          final options = (question.input.options ?? [])
              .map((opt) => opt.toString())
              .toList();
          
          return DropdownButtonFormField<String>(
            value: selected?.toString(),
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
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Pilih jawaban',
            ),
          );
        });
      
      case 'unknown':
        return Text('Tipe pertanyaan tidak dikenali');
        
      default:
        return Text('Unsupported question type: $inputType');
    }
  }


}

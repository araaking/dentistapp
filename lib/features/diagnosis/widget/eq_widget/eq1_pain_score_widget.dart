import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/question_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../provider/diagnosis_provider.dart';

class EqPainScoreWidget extends StatelessWidget {
  final QuestionModel question;
  const EqPainScoreWidget({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DiagnosisProvider>();
    // Get current answers for this question, default to an empty map if null
    final currentAnswers = (provider.answers[question.code] as Map<String, int>?) ?? {};

    return Column(
      children: [
        // Tampilkan gambar lokal untuk EQ1 dengan error handling
        Image.asset(
          'assets/images/e1.png',
          height: 150,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 150,
              color: Colors.grey[200],
              child: Center(
                child: Text(
                  'Gambar tidak ditemukan',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        ...(question.input.areas ?? <String>[]).map((area) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(area, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _scoreEntries(question).map((entry) {
                    final score = entry.key;
                    final isSelected = currentAnswers[area] == score;
                    return GestureDetector(
                      onTap: () {
                         final newAnswers = Map<String, int>.from(currentAnswers);
                         newAnswers[area] = score;
                         provider.answerQuestion(question.code, newAnswers);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade300)
                        ),
                        child: Text(
                          entry.key.toString(),
                          style: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary),
                        ),
                      ),
                    );
                  }).toList(),
                )
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  // Helper to build score range from labels or min/max
  List<MapEntry<int, String>> _scoreEntries(QuestionModel question) {
    final labels = question.input.labels;
    if (labels != null && labels.isNotEmpty) {
      return labels.entries
          .map((e) => MapEntry(int.tryParse(e.key) ?? 0, e.value))
          .toList()
        ..sort((a, b) => a.key.compareTo(b.key));
    }
    final min = question.input.min ?? 0;
    final max = question.input.max ?? 10;
    return List.generate(max - min + 1, (i) => MapEntry(min + i, (min + i).toString()));
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/question_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../provider/diagnosis_provider.dart';

/// Pilihan skor nyeri (0-3) per area untuk pertanyaan E1 dan E4.
/// E4 memeriksa area yang sama dengan E1 sehingga memakai gambar yang sama.
class EqPainScoreWidget extends StatelessWidget {
  final QuestionModel question;
  const EqPainScoreWidget({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DiagnosisProvider>();
    final raw = provider.answers[question.code];
    final currentAnswers = <String, int>{};
    if (raw is Map) {
      raw.forEach((key, value) {
        if (value is num) currentAnswers[key.toString()] = value.toInt();
      });
    }
    final entries = _scoreEntries(question);

    return Column(
      children: [
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
        const SizedBox(height: 12),
        if (entries.any((e) => e.value.isNotEmpty)) _buildLegend(entries),
        const SizedBox(height: 12),
        ...(question.input.areas ?? <String>[]).map((area) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(area,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: entries.map((entry) {
                    final score = entry.key;
                    final isSelected = currentAnswers[area] == score;
                    return Tooltip(
                      message: entry.value,
                      child: GestureDetector(
                        onTap: () {
                          final newAnswers =
                              Map<String, int>.from(currentAnswers);
                          newAnswers[area] = score;
                          provider.answerQuestion(question.code, newAnswers);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.grey.shade300)),
                          child: Text(
                            score.toString(),
                            style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                )
              ],
            ),
          );
        }),
      ],
    );
  }

  /// Keterangan skor, mis. "0 - Tidak Nyeri".
  Widget _buildLegend(List<MapEntry<int, String>> entries) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: entries
            .where((e) => e.value.isNotEmpty)
            .map((e) => Text(
                  e.value,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ))
            .toList(),
      ),
    );
  }

  /// Skor min..max (default 0..3) beserta labelnya (kosong bila tidak ada).
  List<MapEntry<int, String>> _scoreEntries(QuestionModel question) {
    final labels = question.input.labels;
    final min = question.input.min ?? 0;
    final max = question.input.max ?? 3;
    return List.generate(
      max >= min ? max - min + 1 : 0,
      (i) => MapEntry(min + i, labels?[(min + i).toString()] ?? ''),
    );
  }
}

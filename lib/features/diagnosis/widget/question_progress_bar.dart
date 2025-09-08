import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class QuestionProgressBar extends StatelessWidget {
  final int currentQuestion;
  final int totalQuestions;

  const QuestionProgressBar({
    super.key,
    required this.currentQuestion,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalQuestions > 0 ? currentQuestion / totalQuestions : 0.0;
    return Column(
      children: [
        Text(
          'Pertanyaan $currentQuestion dari $totalQuestions',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppColors.primary.withOpacity(0.2),
          color: AppColors.primary,
          minHeight: 8,
        ),
      ],
    );
  }
}

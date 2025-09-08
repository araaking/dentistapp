import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/question_model.dart';
import '../provider/diagnosis_provider.dart';
import '../widget/answer_option_widget.dart';
import '../widget/question_content_builder.dart';
import '../widget/question_progress_bar.dart';

class QuestionScreen extends StatefulWidget {
  const QuestionScreen({super.key});

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  bool _navigated = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DiagnosisProvider>(context, listen: false).fetchQuestions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<DiagnosisProvider>(
          builder: (context, provider, child) {
            return Text('Diagnosis - ${provider.stage.name.toUpperCase()}');
          },
        ),
        leading: Consumer<DiagnosisProvider>(
          builder: (context, provider, child) {
            if (provider.currentQuestionNumber > 1 || provider.stage == DiagnosisStage.eq) {
              return IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => provider.previousQuestion(),
              );
            }
            return const BackButton();
          },
        ),
      ),
      body: Consumer<DiagnosisProvider>(
        builder: (context, provider, child) {
          if (provider.stage == DiagnosisStage.finished && !_navigated) {
            // Hindari navigasi berulang saat rebuild
            _navigated = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              Navigator.of(context).pushReplacementNamed('/diagnosis_result');
            });
          }
          if (provider.state == DiagnosisState.loading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (provider.state == DiagnosisState.error) {
            return Center(child: Text(provider.errorMessage));
          }

          if (provider.state == DiagnosisState.loaded && provider.currentQuestion != null) {
            final question = provider.currentQuestion!;
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  QuestionProgressBar(
                    currentQuestion: provider.currentQuestionNumber,
                    totalQuestions: provider.totalQuestions,
                  ),
                  const SizedBox(height: 40),
                  Text(
                    question.text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 40),
                  
                  // Centralized logic for building the question UI
                  Expanded(
                    child: SingleChildScrollView(
                      child: _buildQuestionBody(provider, question),
                    ),
                  ),

                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      provider.nextQuestion();
                    },
                    child: const Text('Selanjutnya'),
                  ),
                ],
              ),
            );
          }
          if (provider.stage == DiagnosisStage.finished) {
            return const SizedBox.shrink();
          }
          return const Center(child: Text('Memuat...'));
        },
      ),
    );
  }

  // Helper method to decide which widget to build for the question body
  Widget _buildQuestionBody(DiagnosisProvider provider, QuestionModel question) {
    // For simple SQ radio buttons
    if (provider.stage == DiagnosisStage.sq && question.input.type == 'radio') {
      final options = (question.input.options ?? []).map((o) => o.toString()).toList();
      return Column(
        children: options.map((option) {
          final isSelected = provider.answers[question.code] == option;
          return AnswerOption(
            text: option,
            isSelected: isSelected,
            onTap: () {
              provider.answerQuestion(question.code, option);
            },
          );
        }).toList(),
      );
    }
    // For all complex EQ questions
    return QuestionContentBuilder(question: question);
  }
}

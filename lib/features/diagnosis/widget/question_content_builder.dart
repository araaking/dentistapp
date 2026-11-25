import 'package:material_ui/material_ui.dart';

import '../../../core/models/question_model.dart';
import '../../../core/widgets/app_widgets.dart';
import 'choice_options_widget.dart';
import 'eq_widget/eq2_measurement_widget.dart';
import 'eq_widget/eq_pain_score_widget.dart';

/// Memilih widget input yang sesuai dengan `input.type` pertanyaan.
class QuestionContentBuilder extends StatelessWidget {
  final QuestionModel question;

  /// Dipanggil setelah pengguna memilih opsi pada pertanyaan pilihan tunggal.
  final ValueChanged<String>? onChoiceSelected;

  const QuestionContentBuilder({
    super.key,
    required this.question,
    this.onChoiceSelected,
  });

  /// True bila pertanyaan dijawab dengan satu ketukan (pilihan tunggal).
  static bool isSingleChoice(QuestionModel question) =>
      question.input.type == 'radio' || question.input.type == 'select';

  @override
  Widget build(BuildContext context) {
    switch (question.input.type) {
      case 'radio':
      case 'select':
        return ChoiceOptionsWidget(
          question: question,
          onSelected: onChoiceSelected,
        );
      case 'group_select_scores': // E1 dan E4
        return EqPainScoreWidget(question: question);
      case 'composite': // E2
        return const EqMeasurementWidget();
      default:
        return const InlineNotice(
          message:
              'Jenis pertanyaan ini belum didukung di versi aplikasi '
              'Anda. Anda dapat melanjutkan ke langkah berikutnya.',
          tone: NoticeTone.warning,
        );
    }
  }
}

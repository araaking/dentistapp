import 'package:dentistapp/core/models/question_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InputModel labels', () {
    test('list string berindeks skor menjadi map skor -> label', () {
      final input = InputModel.fromJson({
        'type': 'group_select_scores',
        'areas': ['Temporalis', 'Masseter', 'TMJ'],
        'min': 0,
        'max': 3,
        'labels': [
          '0 - Tidak Nyeri',
          '1 - Nyeri Ringan',
          '2 - Nyeri Sedang',
          '3 - Nyeri Berat',
        ],
      });

      expect(input.labels, isNotNull);
      expect(input.labels!.length, 4);
      expect(input.labels!['0'], '0 - Tidak Nyeri');
      expect(input.labels!['3'], '3 - Nyeri Berat');
      expect(input.areas, ['Temporalis', 'Masseter', 'TMJ']);
      expect(input.min, 0);
      expect(input.max, 3);
    });

    test('format lama (list of map) tetap didukung', () {
      final labels = InputModel.parseLabels([
        {'0': 'Tidak Nyeri'},
        {'1': 'Ringan'},
      ]);
      expect(labels, {'0': 'Tidak Nyeri', '1': 'Ringan'});
    });

    test('format map didukung', () {
      final labels = InputModel.parseLabels({'0': 'A', 1: 'B'});
      expect(labels, {'0': 'A', '1': 'B'});
    });

    test('tanpa labels menghasilkan null', () {
      final input = InputModel.fromJson({
        'type': 'radio',
        'options': ['Ya', 'Tidak'],
        'default': 'Tidak',
      });
      expect(input.labels, isNull);
      expect(input.options, ['Ya', 'Tidak']);
      expect(input.defaultValue, 'Tidak');
    });
  });

  test('AllQuestionsModel mengurai sq dan eq', () {
    final all = AllQuestionsModel.fromJson({
      'sq': [
        {
          'code': 'SQ1',
          'text': 'Apakah Anda merasakan nyeri?',
          'input': {
            'type': 'radio',
            'options': ['Ya', 'Tidak'],
            'default': 'Tidak',
          },
        },
      ],
      'eq': [
        {
          'code': 'E3',
          'text': 'Bunyi sendi',
          'input': {
            'type': 'radio',
            'options': [
              {'value': 'Tidak ada', 'label': 'Tidak ada'},
              {'value': 'Kliking', 'label': 'Kliking', 'audio': 'https://x/a.wav'},
            ],
            'default': 'Tidak ada',
          },
        },
      ],
    });

    expect(all.sq.single.code, 'SQ1');
    expect(all.eq.single.input.options!.length, 2);
    expect(all.eq.single.input.defaultValue, 'Tidak ada');
  });
}

// Model utama yang menampung kedua jenis pertanyaan
class AllQuestionsModel {
  final List<QuestionModel> sq;
  final List<QuestionModel> eq;

  AllQuestionsModel({required this.sq, required this.eq});

  factory AllQuestionsModel.fromJson(Map<String, dynamic> json) {
    final sqData = json['sq'];
    final eqData = json['eq'];

    return AllQuestionsModel(
      sq: sqData is List
          ? sqData
              .whereType<Map>()
              .map((x) => QuestionModel.fromJson(Map<String, dynamic>.from(x)))
              .toList()
          : <QuestionModel>[],
      eq: eqData is List
          ? eqData
              .whereType<Map>()
              .map((x) => QuestionModel.fromJson(Map<String, dynamic>.from(x)))
              .toList()
          : <QuestionModel>[],
    );
  }
}

// Model untuk satu pertanyaan
class QuestionModel {
  final String code;
  final String text;
  final InputModel input;

  QuestionModel({
    required this.code,
    required this.text,
    required this.input,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    try {
      final inputData = json['input'];
      InputModel inputModel;

      if (inputData is Map) {
        try {
          inputModel = InputModel.fromJson(Map<String, dynamic>.from(inputData));
        } catch (_) {
          inputModel = InputModel(type: 'unknown');
        }
      } else {
        inputModel = InputModel(type: 'unknown');
      }

      return QuestionModel(
        code: json['code']?.toString() ?? 'unknown',
        text: json['text']?.toString() ?? '',
        input: inputModel,
      );
    } catch (_) {
      return QuestionModel(
        code: 'error',
        text: 'Pertanyaan tidak dapat dimuat',
        input: InputModel(type: 'error'),
      );
    }
  }
}

// Model untuk detail input dari setiap pertanyaan
class InputModel {
  final String type;
  final List<dynamic>? options; // Bisa List<String> atau List<Map>
  final dynamic defaultValue; // Bisa String, angka, Map, atau null
  final List<String>? areas;
  final int? min;
  final int? max;

  /// Label skor untuk pertanyaan `group_select_scores`. Kunci = skor sebagai
  /// string ("0", "1", ...), nilai = teks label (mis. "0 - Tidak Nyeri").
  final Map<String, String>? labels;

  InputModel({
    required this.type,
    this.options,
    this.defaultValue,
    this.areas,
    this.min,
    this.max,
    this.labels,
  });

  factory InputModel.fromJson(Map<String, dynamic> json) {
    final optionsData = json['options'];
    final areasData = json['areas'];

    return InputModel(
      type: json['type']?.toString() ?? 'unknown',
      options: optionsData is List ? optionsData : null,
      defaultValue: json['default'],
      areas: areasData is List
          ? areasData.map((a) => a.toString()).toList()
          : null,
      min: _asInt(json['min']),
      max: _asInt(json['max']),
      labels: parseLabels(json['labels']),
    );
  }

  /// API mengirim `labels` sebagai list string berindeks skor
  /// (`["0 - Tidak Nyeri", "1 - Ringan", ...]`). Format lama (list of map atau
  /// map) tetap didukung.
  static Map<String, String>? parseLabels(dynamic data) {
    if (data is List) {
      final result = <String, String>{};
      for (var i = 0; i < data.length; i++) {
        final item = data[i];
        if (item is Map) {
          item.forEach((key, value) {
            result[key.toString()] = value.toString();
          });
        } else if (item != null) {
          result[i.toString()] = item.toString();
        }
      }
      return result;
    }
    if (data is Map) {
      return data.map((k, v) => MapEntry(k.toString(), v.toString()));
    }
    return null;
  }

  static int? _asInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

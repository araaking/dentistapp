// Model utama yang menampung kedua jenis pertanyaan
class AllQuestionsModel {
  final List<QuestionModel> sq;
  final List<QuestionModel> eq;

  AllQuestionsModel({required this.sq, required this.eq});

  factory AllQuestionsModel.fromJson(Map<String, dynamic> json) {
    return AllQuestionsModel(
      sq: List<QuestionModel>.from(
          json['sq']?.map((x) => QuestionModel.fromJson(x)) ?? []),
      eq: List<QuestionModel>.from(
          json['eq']?.map((x) => QuestionModel.fromJson(x)) ?? []),
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
    // PERBAIKAN: Tambahkan pengecekan tipe untuk 'input'
    // untuk memastikan datanya adalah Map sebelum diparsing.
    // Jika bukan Map (misalnya List kosong), kita berikan InputModel kosong.
    final inputData = json['input'];
    return QuestionModel(
      code: json['code'],
      text: json['text'],
      input: inputData is Map<String, dynamic>
          ? InputModel.fromJson(inputData)
          : InputModel(type: 'unknown'), // Fallback jika input tidak valid
    );
  }
}

// Model untuk detail input dari setiap pertanyaan
class InputModel {
  final String type;
  final List<dynamic>? options; // Bisa List<String> atau List<Map>
  final dynamic defaultValue; // Bisa String atau null
  final List<String>? areas;
  final int? min;
  final int? max;
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
    return InputModel(
      type: json['type'],
      options: json['options'],
      defaultValue: json['default'],
      areas: json['areas'] != null ? List<String>.from(json['areas']) : null,
      min: json['min'],
      max: json['max'],
      labels: json['labels'] != null
          ? Map<String, String>.from(json['labels'])
          : null,
    );
  }
}

// Model utama yang menampung kedua jenis pertanyaan
class AllQuestionsModel {
  final List<QuestionModel> sq;
  final List<QuestionModel> eq;

  AllQuestionsModel({required this.sq, required this.eq});

  factory AllQuestionsModel.fromJson(Map<String, dynamic> json) {
    // Handle incomplete JSON - provide empty lists if fields are missing
    final sqData = json['sq'];
    final eqData = json['eq'];
    
    return AllQuestionsModel(
      sq: sqData is List 
          ? List<QuestionModel>.from(sqData.map((x) => QuestionModel.fromJson(x))) 
          : [],
      eq: eqData is List
          ? List<QuestionModel>.from(eqData.map((x) => QuestionModel.fromJson(x)))
          : [],
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
      print('=== DEBUG: Parsing question JSON ===');
      print('JSON: $json');
      
      // Handle different option formats with null safety
      dynamic optionsData = json['input']?['options'];
      print('=== DEBUG: Options data: $optionsData ===');
      
      // Handle input data dengan mempertahankan struktur asli options
      final inputData = json['input'];
      InputModel inputModel;
      
      if (inputData is Map<String, dynamic>) {
        try {
          inputModel = InputModel.fromJson(inputData);
          // JANGAN override options, biarkan struktur asli tetap utuh
        } catch (e) {
          // Fallback if InputModel parsing fails
          print('Error parsing input data: $e');
          inputModel = InputModel(type: 'unknown');
        }
      } else {
        inputModel = InputModel(type: 'unknown');
      }
      
      return QuestionModel(
        code: json['code']?.toString() ?? 'unknown',
        text: json['text']?.toString() ?? 'No text',
        input: inputModel,
      );
    } catch (e) {
      // Comprehensive error handling for entire parsing process
      print('=== DEBUG: Error parsing question: $e ===');
      print('Problematic question data: $json');
      return QuestionModel(
        code: 'error',
        text: 'Failed to parse question',
        input: InputModel(type: 'error'),
      );
    }
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
    print('=== DEBUG: InputModel.fromJson: $json ===');
    
    // Handle labels conversion - PHP associative array becomes List in JSON
    Map<String, String>? labels;
    final labelsData = json['labels'];
    if (labelsData is List) {
      // Convert List to Map (for PHP associative array compatibility)
      labels = {};
      for (var item in labelsData) {
        if (item is Map) {
          item.forEach((key, value) {
            labels![key.toString()] = value.toString();
          });
        }
      }
    } else if (labelsData is Map) {
      labels = Map<String, String>.from(labelsData);
    }
    
    return InputModel(
      type: json['type'],
      options: json['options'],
      defaultValue: json['default'],
      areas: json['areas'] != null ? List<String>.from(json['areas']) : null,
      min: json['min'],
      max: json['max'],
      labels: labels, // Use the converted labels
    );
  }
}

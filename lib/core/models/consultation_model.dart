class ConsultationModel {
  final int id;
  final int patientId;
  final DateTime consultationDate;
  final List<DiagnosisModel> diagnoses;
  // Jawaban bisa null jika tidak di-load, misal di halaman riwayat
  final List<AnswerModel>? answers;

  ConsultationModel({
    required this.id,
    required this.patientId,
    required this.consultationDate,
    required this.diagnoses,
    this.answers,
  });

  factory ConsultationModel.fromJson(Map<String, dynamic> json) {
    return ConsultationModel(
      id: json['id'],
      patientId: json['patient_id'],
      consultationDate: DateTime.parse(json['consultation_date']),
      diagnoses: List<DiagnosisModel>.from(
          json['diagnoses']?.map((x) => DiagnosisModel.fromJson(x)) ?? []),
      answers: json['answers'] != null
          ? List<AnswerModel>.from(
              json['answers'].map((x) => AnswerModel.fromJson(x)))
          : null,
    );
  }
}

class DiagnosisModel {
  final int id;
  final String name;

  DiagnosisModel({required this.id, required this.name});

  factory DiagnosisModel.fromJson(Map<String, dynamic> json) {
    return DiagnosisModel(
      id: json['id'],
      name: json['name'],
    );
  }
}

class AnswerModel {
  final int id;
  final String questionCode;
  final String answer; // Jawaban disimpan sebagai JSON string atau string biasa
  final String type;

  AnswerModel({
    required this.id,
    required this.questionCode,
    required this.answer,
    required this.type,
  });

  factory AnswerModel.fromJson(Map<String, dynamic> json) {
    return AnswerModel(
      id: json['id'],
      questionCode: json['question_code'],
      answer: json['answer'],
      type: json['type'],
    );
  }
}

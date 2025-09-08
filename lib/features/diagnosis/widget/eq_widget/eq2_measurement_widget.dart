import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/question_model.dart';
import '../../provider/diagnosis_provider.dart';

class EqMeasurementWidget extends StatelessWidget {
  final QuestionModel question;
  const EqMeasurementWidget({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DiagnosisProvider>();
    final currentAnswers = (provider.answers['E2'] as Map<String, dynamic>?) ?? {};
    final photoAnswer = currentAnswers['photo'] as File?;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Pengukuran Bukaan Mulut (mm)",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Contoh: 40',
            suffixText: 'mm',
          ),
          onChanged: (value) {
            // Store the text value dengan struktur yang benar
            final newAnswers = Map<String, dynamic>.from(currentAnswers);
            newAnswers['opening_mm'] = value;
            provider.answerQuestion('E2', newAnswers);  // ← GUNAKAN 'E2', BUKAN 'E2_opening'
          },
        ),
        const SizedBox(height: 24),
        const Text(
          "Ambil Foto Wajah",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => provider.takePictureForEQ2(),
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: photoAnswer != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(photoAnswer, fit: BoxFit.cover),
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                      SizedBox(height: 8),
                      Text("Ketuk untuk mengambil gambar"),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

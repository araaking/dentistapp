import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/question_model.dart';
import '../../provider/diagnosis_provider.dart';

class EqMeasurementWidget extends StatefulWidget {
  final QuestionModel question;
  const EqMeasurementWidget({super.key, required this.question});

  @override
  State<EqMeasurementWidget> createState() => _EqMeasurementWidgetState();
}

class _EqMeasurementWidgetState extends State<EqMeasurementWidget> {
  late final TextEditingController _openingController;

  @override
  void initState() {
    super.initState();
    // Pulihkan nilai yang sudah diketik bila pengguna kembali ke pertanyaan ini.
    final e2 = context.read<DiagnosisProvider>().answers['E2'];
    final saved = e2 is Map ? e2['opening_mm'] : null;
    _openingController = TextEditingController(text: saved?.toString() ?? '');
  }

  @override
  void dispose() {
    _openingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DiagnosisProvider>();
    final e2 = provider.answers['E2'];
    final photo = e2 is Map ? e2['photo'] : null;
    final File? photoAnswer = photo is File ? photo : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pengukuran Bukaan Mulut (mm)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _openingController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: 'Contoh: 40',
            suffixText: 'mm',
            errorText: provider.validationError,
          ),
          onChanged: (value) => provider.setOpeningMm(value),
        ),
        const SizedBox(height: 24),
        const Text(
          'Ambil Foto Wajah (opsional)',
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
                      Text('Ketuk untuk mengambil gambar'),
                    ],
                  ),
          ),
        ),
        if (provider.photoError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              provider.photoError!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
      ],
    );
  }
}

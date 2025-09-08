import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/data/repositories/consultation_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../provider/diagnosis_provider.dart';

// Mapping penjelasan untuk setiap jenis diagnosis
const Map<String, String> diagnosisDescriptions = {
  'Myalgia': 'Nyeri otot pada rahang yang disebabkan oleh ketegangan atau kelelahan otot pengunyah.',
  'Arthralgia': 'Nyeri pada sendi rahang (temporomandibular joint) tanpa disertai kerusakan struktural.',
  'Headache attributed to TMD (HA-TMD)': 'Sakit kepala yang disebabkan oleh gangguan pada sendi rahang dan otot pengunyah.',
  'Joint-related TMD': 'Gangguan yang terkait dengan struktur internal sendi rahang. Ini bisa mencakup bunyi sendi (klik), rahang terkunci (terbuka atau tertutup), atau perubahan degeneratif pada sendi.',
  'No specific TMD diagnosis found.': 'Tidak ditemukan diagnosis TMD spesifik berdasarkan jawaban yang diberikan.'
};

class DiagnosisResultScreen extends StatefulWidget {
  final ConsultationRepository consultationRepository;
  final dynamic consultationData; // Untuk data dari history

  const DiagnosisResultScreen({
    super.key,
    required this.consultationRepository,
    this.consultationData,
  });

  @override
  State<DiagnosisResultScreen> createState() => _DiagnosisResultScreenState();
}

class _DiagnosisResultScreenState extends State<DiagnosisResultScreen> {
  Map<String, dynamic>? _result;
  String? _error;
  bool _submitting = true;

  @override
  void initState() {
    super.initState();
    
    // Jika ada consultationData dari history, gunakan data tersebut
    if (widget.consultationData != null) {
      _result = widget.consultationData is Map ? Map<String, dynamic>.from(widget.consultationData) : {'consultation': widget.consultationData};
      _submitting = false;
    } else {
      // Jika tidak ada data dari history, submit answers seperti biasa
      _submitAnswers();
    }
  }

  Future<void> _submitAnswers() async {
    final provider = context.read<DiagnosisProvider>();
    try {
      final sqCodes = provider.sqCodes.toSet();
      final eqCodes = provider.eqCodes.toSet();

      final Map<String, dynamic> sq = {};
      final Map<String, dynamic> eq = {};
      File? e2Photo;

      provider.answers.forEach((key, value) {
        if (key == 'E2_photo' && value is File) {
          e2Photo = value;
          return;
        }
        if (key == 'E2_opening') {
          eq[key] = value;
          return;
        }
        if (sqCodes.contains(key)) {
          sq[key] = value;
        } else if (eqCodes.contains(key)) {
          eq[key] = value;
        }
      });

      final res = await widget.consultationRepository.submitConsultation(
        sqAnswers: sq,
        eqAnswers: eq,
        e2Photo: e2Photo,
      );
      if (!mounted) return;
      setState(() {
        _result = res;
        _submitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hasil Diagnosis'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_submitting) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return _ErrorState(message: _error!);
    }
    final data = _result ?? {};

    // Cari struktur diagnoses di berbagai kemungkinan bentuk response
    List<dynamic> diagnoses = [];
    if (data['diagnoses'] is List) {
      diagnoses = data['diagnoses'] as List;
    } else if (data['consultation'] is Map && (data['consultation']['diagnoses'] is List)) {
      diagnoses = (data['consultation']['diagnoses'] as List);
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Kemungkinan Diagnosis',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (diagnoses.isEmpty)
            const Center(child: Text('Tidak ada diagnosis tersedia.', style: TextStyle(color: AppColors.textSecondary)))
          else
            ...diagnoses.map((d) {
              String name = '';
              if (d is Map && d['name'] != null) {
                name = d['name'].toString();
              } else {
                name = d.toString();
              }
              return _DiagnosisItem(name: name);
            }).toList(),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              if (!mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
            },
            child: const Text('Kembali ke Beranda'),
          )
        ],
      ),
    );
  }
}

class _DiagnosisItem extends StatelessWidget {
  final String name;
  const _DiagnosisItem({required this.name});

  @override
  Widget build(BuildContext context) {
    final description = diagnosisDescriptions[name] ?? 'Penjelasan tidak tersedia.';
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.local_hospital, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600, 
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text('Gagal memuat hasil:\n$message', textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kembali'),
          )
        ],
      ),
    );
  }
}

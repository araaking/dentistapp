import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/repositories/consultation_repository.dart';
import '../widgets/history_item.dart';

class HistoryScreen extends StatefulWidget {
  final ConsultationRepository consultationRepository;

  const HistoryScreen({super.key, required this.consultationRepository});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> _consultations = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadConsultations();
  }

  Future<void> _loadConsultations() async {
    try {
      final consultations = await widget.consultationRepository.getConsultations();
      setState(() {
        _consultations = consultations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Diagnosis'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Gagal memuat riwayat:\n$_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadConsultations,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_consultations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history_toggle_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Belum ada riwayat diagnosis',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Mulai diagnosis pertama Anda untuk melihat riwayat di sini',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadConsultations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _consultations.length,
        itemBuilder: (context, index) {
          final consultation = _consultations[index];
          return HistoryItem(
            consultation: consultation,
            onTap: () {
              // Navigate to detail view
              _showConsultationDetail(consultation);
            },
          );
        },
      ),
    );
  }

  void _showConsultationDetail(dynamic consultation) {
    // Untuk sementara tampilkan dialog detail
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detail Diagnosis'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tanggal: ${consultation['consultation_date'] ?? 'Tidak diketahui'}'),
            const SizedBox(height: 8),
            const Text('Diagnosis:'),
            ..._extractDiagnoses(consultation).map((diagnosis) => 
              Text('• $diagnosis')
            ).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed(
                '/diagnosis_result',
                arguments: consultation,
              );
            },
            child: const Text('Lihat Lengkap'),
          ),
        ],
      ),
    );
  }

  List<String> _extractDiagnoses(dynamic consultation) {
    if (consultation['diagnoses'] is List) {
      return (consultation['diagnoses'] as List).map((d) {
        if (d is Map && d['name'] != null) return d['name'].toString();
        return d.toString();
      }).toList();
    }
    return [];
  }
}

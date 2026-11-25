import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/constants.dart';
import '../../authentication/provider/auth_provider.dart';
import '../provider/diagnosis_provider.dart';

// Mapping penjelasan untuk setiap jenis diagnosis
const Map<String, String> diagnosisDescriptions = {
  'Myalgia': 'Nyeri otot pada rahang yang disebabkan oleh ketegangan atau kelelahan otot pengunyah.',
  'Arthralgia': 'Nyeri pada sendi rahang (temporomandibular joint) tanpa disertai kerusakan struktural.',
  'Headache attributed to TMD (HA-TMD)': 'Sakit kepala yang disebabkan oleh gangguan pada sendi rahang dan otot pengunyah.',
  'Joint-related TMD': 'Gangguan yang terkait dengan struktur internal sendi rahang. Ini bisa mencakup bunyi sendi (klik), rahang terkunci (terbuka atau tertutup), atau perubahan degeneratif pada sendi.',
  'No specific TMD diagnosis found.': 'Tidak ditemukan diagnosis TMD spesifik berdasarkan jawaban yang diberikan.'
};

/// Menampilkan hasil diagnosis.
///
/// - Diagnosis baru (`consultationData == null`): pengiriman dimiliki oleh
///   [DiagnosisProvider.submitConsultation] (hanya sekali); layar ini hanya
///   memicu dan mengamati statusnya.
/// - Dari riwayat: menampilkan data konsultasi yang diberikan sebagai argumen.
class DiagnosisResultScreen extends StatefulWidget {
  final dynamic consultationData; // Untuk data dari history

  const DiagnosisResultScreen({
    super.key,
    this.consultationData,
  });

  @override
  State<DiagnosisResultScreen> createState() => _DiagnosisResultScreenState();
}

class _DiagnosisResultScreenState extends State<DiagnosisResultScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.consultationData == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<DiagnosisProvider>().submitConsultation();
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
    final history = widget.consultationData;
    if (history != null) {
      final data = history is Map
          ? Map<String, dynamic>.from(history)
          : <String, dynamic>{'consultation': history};
      return _ResultContent(data: data);
    }

    return Consumer<DiagnosisProvider>(
      builder: (context, provider, child) {
        switch (provider.submissionState) {
          case SubmissionState.error:
            return _ErrorState(
              message: provider.submissionError,
              onRetry: () => provider.submitConsultation(),
            );
          case SubmissionState.success:
            return _ResultContent(data: provider.submissionResult ?? {});
          case SubmissionState.idle:
          case SubmissionState.submitting:
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('Menyimpan hasil diagnosis...',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
        }
      },
    );
  }
}

class _ResultContent extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ResultContent({required this.data});

  @override
  Widget build(BuildContext context) {
    // Cari struktur diagnoses di berbagai kemungkinan bentuk response
    final consultation = data['consultation'];
    List<dynamic> diagnoses = [];
    if (data['diagnoses'] is List) {
      diagnoses = data['diagnoses'] as List;
    } else if (consultation is Map && consultation['diagnoses'] is List) {
      diagnoses = consultation['diagnoses'] as List;
    }

    String? photoUrl;
    final rawPhoto = data['e2_photo_url'] ??
        (consultation is Map ? consultation['e2_photo_url'] : null);
    if (rawPhoto is String && rawPhoto.isNotEmpty) {
      photoUrl = AppConstants.resolveApiUrl(rawPhoto);
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Kemungkinan Diagnosis',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (diagnoses.isEmpty)
                    const Center(
                        child: Text('Tidak ada diagnosis tersedia.',
                            style: TextStyle(color: AppColors.textSecondary)))
                  else
                    ...diagnoses.map((d) {
                      String name = '';
                      if (d is Map && d['name'] != null) {
                        name = d['name'].toString();
                      } else {
                        name = d.toString();
                      }
                      return _DiagnosisItem(name: name);
                    }),
                  if (photoUrl != null) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Foto Bukaan Mulut',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    _ConsultationPhoto(url: photoUrl),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/home', (route) => false);
            },
            child: const Text('Kembali ke Beranda'),
          )
        ],
      ),
    );
  }
}

/// Foto konsultasi: URL privat, wajib memakai header Authorization.
class _ConsultationPhoto extends StatelessWidget {
  final String url;
  const _ConsultationPhoto({required this.url});

  @override
  Widget build(BuildContext context) {
    final token = context.read<AuthProvider>().token;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            height: 220,
            color: Colors.grey.shade200,
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 220,
            color: Colors.grey.shade200,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.broken_image_outlined, color: Colors.grey, size: 40),
                  SizedBox(height: 8),
                  Text('Foto tidak dapat dimuat',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
          );
        },
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
                  color: AppColors.primary.withValues(alpha: 0.1),
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
  final VoidCallback? onRetry;
  const _ErrorState({required this.message, this.onRetry});

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
          Text('Gagal menyimpan hasil:\n$message', textAlign: TextAlign.center),
          const SizedBox(height: 24),
          if (onRetry != null) ...[
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Coba Lagi'),
            ),
            const SizedBox(height: 12),
          ],
          OutlinedButton(
            onPressed: () => Navigator.of(context)
                .pushNamedAndRemoveUntil('/home', (route) => false),
            child: const Text('Kembali ke Beranda'),
          )
        ],
      ),
    );
  }
}

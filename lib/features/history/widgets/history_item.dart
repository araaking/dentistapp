import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class HistoryItem extends StatelessWidget {
  final dynamic consultation;
  final VoidCallback onTap;

  const HistoryItem({
    super.key,
    required this.consultation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final date = _formatDate(consultation['consultation_date']);
    final diagnoses = _extractDiagnoses(consultation);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getMainDiagnosis(diagnoses),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    if (diagnoses.length > 1) ...[
                      const SizedBox(height: 4),
                      Text(
                        '+ ${diagnoses.length - 1} diagnosis lainnya',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Tanggal tidak diketahui';
    
    final dateStr = date.toString();
    if (dateStr.length >= 10) {
      return dateStr.substring(0, 10); // Format YYYY-MM-DD
    }
    return dateStr;
  }

  List<String> _extractDiagnoses(dynamic consultation) {
    if (consultation['diagnoses'] is List) {
      return (consultation['diagnoses'] as List).map((d) {
        if (d is Map && d['name'] != null) return d['name'].toString();
        return d.toString();
      }).toList();
    }
    return ['Tidak ada diagnosis'];
  }

  String _getMainDiagnosis(List<String> diagnoses) {
    if (diagnoses.isEmpty) return 'Tidak ada diagnosis';
    return diagnoses.first;
  }
}

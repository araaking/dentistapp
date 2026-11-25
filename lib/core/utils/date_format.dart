const List<String> _monthNames = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

/// Memformat tanggal ISO-8601 dari API menjadi "12 September 2025"
/// (zona waktu perangkat). Mengembalikan [fallback] bila tidak dapat diparse.
String formatDateId(dynamic value,
    {String fallback = 'Tanggal tidak diketahui'}) {
  if (value == null) return fallback;
  final parsed = DateTime.tryParse(value.toString());
  if (parsed == null) return fallback;
  final d = parsed.toLocal();
  return '${d.day.toString().padLeft(2, '0')} ${_monthNames[d.month - 1]} ${d.year}';
}

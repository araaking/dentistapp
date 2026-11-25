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

DateTime? _toLocalDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toLocal();
  return DateTime.tryParse(value.toString())?.toLocal();
}

/// Memformat tanggal (DateTime atau teks ISO-8601 dari API) menjadi
/// "12 September 2025" pada zona waktu perangkat. Mengembalikan [fallback]
/// bila tidak dapat diparse.
String formatDateId(
  dynamic value, {
  String fallback = 'Tanggal tidak diketahui',
}) {
  final d = _toLocalDate(value);
  if (d == null) return fallback;
  return '${d.day} ${_monthNames[d.month - 1]} ${d.year}';
}

/// Seperti [formatDateId] ditambah jam, mis. "12 September 2025, 08.30".
String formatDateTimeId(
  dynamic value, {
  String fallback = 'Tanggal tidak diketahui',
}) {
  final d = _toLocalDate(value);
  if (d == null) return fallback;
  final hh = d.hour.toString().padLeft(2, '0');
  final mm = d.minute.toString().padLeft(2, '0');
  return '${formatDateId(d)}, $hh.$mm';
}

/// Tanggal kalender (tanpa konversi zona waktu), mis. tanggal lahir.
String formatCalendarDateId(DateTime? date, {String fallback = '-'}) {
  if (date == null) return fallback;
  return '${date.day} ${_monthNames[date.month - 1]} ${date.year}';
}

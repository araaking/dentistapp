import '../errors/exceptions.dart';

/// Memastikan [data] adalah objek JSON (Map). Jika bukan, lempar [ApiException].
Map<String, dynamic> asJsonMap(dynamic data) {
  if (data is Map) {
    return Map<String, dynamic>.from(data);
  }
  throw ApiException(message: 'Respons server tidak valid.');
}

import 'package:dentistapp/core/storage/token_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Storage palsu: semua pemanggilan melempar error (mis. token lama dari
/// flutter_secure_storage v9 yang tidak bisa didekripsi setelah upgrade).
class _BrokenStorage implements FlutterSecureStorage {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('rusak');
}

void main() {
  test('load gagal dibaca -> token null tanpa melempar (user login ulang)',
      () async {
    final storage = TokenStorage(_BrokenStorage());
    expect(await storage.load(), isNull);
    expect(storage.token, isNull);
  });

  test('save tetap menyimpan token di memori walau storage rusak', () async {
    final storage = TokenStorage(_BrokenStorage());
    await storage.save('abc');
    expect(storage.token, 'abc');
    await storage.clear();
    expect(storage.token, isNull);
  });
}

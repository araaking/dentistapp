import 'package:flutter/foundation.dart';

import '../../../core/data/repositories/consultation_repository.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/models/consultation.dart';

/// Riwayat pemeriksaan pengguna. Satu sumber data untuk Beranda dan tab
/// Riwayat, sehingga keduanya selalu menampilkan daftar yang sama.
class HistoryProvider extends ChangeNotifier {
  final ConsultationRepository _repository;

  HistoryProvider(this._repository);

  List<Consultation> _items = const [];
  bool _isLoading = false;
  bool _hasLoaded = false;
  bool _reloadRequested = false;
  String? _error;
  int _epoch = 0; // naik setiap clear() agar respons lama diabaikan

  List<Consultation> get items => _items;
  bool get isLoading => _isLoading;

  /// True setelah pemuatan pertama berhasil.
  bool get hasLoaded => _hasLoaded;
  String? get error => _error;
  Consultation? get latest => _items.isEmpty ? null : _items.first;

  /// Memuat ulang riwayat (terbaru dulu). Daftar lama tetap tampil selama
  /// pemuatan agar layar tidak berkedip.
  Future<void> load() async {
    if (_isLoading) {
      // Permintaan baru saat masih memuat (mis. tepat setelah hasil baru
      // tersimpan): ulangi sekali lagi setelah selesai agar data tidak basi.
      _reloadRequested = true;
      return;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    final epoch = _epoch;

    try {
      final items = await _repository.getConsultationHistory();
      if (epoch != _epoch) return;
      _items = items;
      _hasLoaded = true;
    } catch (e) {
      if (epoch != _epoch) return;
      _error = ApiException.messageOf(e);
    } finally {
      if (epoch == _epoch) {
        _isLoading = false;
        notifyListeners();
      }
    }

    if (_reloadRequested && epoch == _epoch) {
      _reloadRequested = false;
      await load();
    }
  }

  /// Mengosongkan riwayat (logout / sesi berakhir).
  void clear() {
    _epoch++;
    _items = const [];
    _isLoading = false;
    _hasLoaded = false;
    _reloadRequested = false;
    _error = null;
    notifyListeners();
  }
}

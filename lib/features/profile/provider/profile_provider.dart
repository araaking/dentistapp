import 'package:flutter/foundation.dart';

import '../../../core/data/repositories/patient_repository.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/models/patient.dart';

class ProfileProvider extends ChangeNotifier {
  final PatientRepository _patientRepository;

  ProfileProvider(this._patientRepository);

  Patient? _patient;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasLoaded = false;
  String? _error;
  String? _saveError;
  int _epoch = 0; // naik setiap clear() agar respons lama diabaikan

  /// Profil pasien, atau null bila belum dimuat / belum dibuat.
  Patient? get patient => _patient;

  /// Sedang memuat profil (bukan menyimpan).
  bool get isLoading => _isLoading;

  /// Sedang menyimpan perubahan dari layar Edit Profil.
  bool get isSaving => _isSaving;

  /// True setelah profil berhasil dimuat minimal sekali.
  bool get hasLoaded => _hasLoaded;

  /// Error pemuatan profil.
  String? get error => _error;

  /// Error penyimpanan (ditampilkan di layar Edit Profil).
  String? get saveError => _saveError;

  Future<void> loadPatientProfile() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    final epoch = _epoch;

    try {
      final patient = await _patientRepository.getPatient();
      if (epoch != _epoch) return;
      _patient = patient;
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
  }

  /// Membuat profil ([isUpdate] false) atau memperbaruinya. Mengembalikan
  /// true bila berhasil; pesan kegagalan ada di [saveError].
  Future<bool> savePatientProfile(
    Map<String, dynamic> data, {
    required bool isUpdate,
  }) async {
    if (_isSaving) return false;
    _isSaving = true;
    _saveError = null;
    notifyListeners();
    final epoch = _epoch;

    try {
      final patient = isUpdate
          ? await _patientRepository.updatePatient(data)
          : await _patientRepository.createPatient(data);
      if (epoch != _epoch) return false;
      _patient = patient ?? _patient;
      _hasLoaded = true;
      return true;
    } catch (e) {
      if (epoch != _epoch) return false;
      _saveError = ApiException.messageOf(e);
      return false;
    } finally {
      if (epoch == _epoch) {
        _isSaving = false;
        notifyListeners();
      }
    }
  }

  void clearSaveError() {
    if (_saveError == null) return;
    _saveError = null;
    notifyListeners();
  }

  /// Mengosongkan seluruh data profil (dipanggil saat logout / sesi berakhir).
  void clear() {
    _epoch++;
    _patient = null;
    _isLoading = false;
    _isSaving = false;
    _hasLoaded = false;
    _error = null;
    _saveError = null;
    notifyListeners();
  }
}

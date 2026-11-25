import 'package:flutter/material.dart';
import '../../../core/data/repositories/patient_repository.dart';
import '../../../core/errors/exceptions.dart';

class ProfileProvider extends ChangeNotifier {
  final PatientRepository _patientRepository;

  ProfileProvider(this._patientRepository);

  Map<String, dynamic>? _patientData;
  bool _isLoading = false;
  String? _error;
  int _epoch = 0; // naik setiap clear() agar respons lama diabaikan

  Map<String, dynamic>? get patientData => _patientData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPatientProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    final epoch = _epoch;

    try {
      final response = await _patientRepository.getPatient();
      if (epoch != _epoch) return;
      final patient = response['patient'];
      // Tanpa kunci `patient` berarti profil belum dibuat (404).
      _patientData =
          patient is Map ? Map<String, dynamic>.from(patient) : null;
    } catch (e) {
      if (epoch != _epoch) return;
      _error = ApiException.messageOf(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createPatientProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _patientRepository.createPatient(data);
      final patient = response['patient'];
      _patientData =
          patient is Map ? Map<String, dynamic>.from(patient) : _patientData;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = ApiException.messageOf(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePatientProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _patientRepository.updatePatient(data);
      final patient = response['patient'];
      _patientData =
          patient is Map ? Map<String, dynamic>.from(patient) : _patientData;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = ApiException.messageOf(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Mengosongkan seluruh data profil (dipanggil saat logout / sesi berakhir).
  void clear() {
    _epoch++;
    _patientData = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}

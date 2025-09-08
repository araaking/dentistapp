import 'package:flutter/material.dart';
import '../../../core/data/repositories/patient_repository.dart';

class ProfileProvider extends ChangeNotifier {
  final PatientRepository _patientRepository;

  ProfileProvider(this._patientRepository);

  Map<String, dynamic>? _patientData;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get patientData => _patientData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPatientProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _patientRepository.getPatient();
      if (response.containsKey('patient')) {
        _patientData = response['patient'];
      } else if (response.containsKey('message')) {
        _patientData = null;
      }
    } catch (e) {
      _error = e.toString();
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
      _patientData = response['patient'];
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
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
      _patientData = response['patient'];
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

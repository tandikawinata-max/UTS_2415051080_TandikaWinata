import 'package:flutter/foundation.dart';

import '../models/body_measurement.dart';
import '../repositories/measurement_repository.dart';

class MeasurementProvider extends ChangeNotifier {
  final MeasurementRepository _repository;

  List<BodyMeasurement> _measurements = [];
  String? _activeMeasurementId;
  String? _errorMessage;

  bool _isLoading = false;
  bool _isDisposed = false;

  MeasurementProvider(this._repository);

  List<BodyMeasurement> get measurements => _measurements;
  String? get activeMeasurementId => _activeMeasurementId;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  BodyMeasurement? get activeMeasurement {
    final id = _activeMeasurementId;

    if (id == null) {
      return null;
    }

    return findById(id);
  }

  BodyMeasurement? findById(String id) {
    for (final measurement in _measurements) {
      if (measurement.id == id) {
        return measurement;
      }
    }

    return null;
  }

  Future<void> loadMeasurements() async {
    if (_isLoading || _isDisposed) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final measurements = await _repository.getMeasurements();

      if (_isDisposed) {
        return;
      }

      _measurements = List<BodyMeasurement>.unmodifiable(measurements);

      final activeId = _activeMeasurementId;

      if (activeId != null && findById(activeId) == null) {
        _activeMeasurementId = null;
      }
    } catch (error) {
      debugPrint('Gagal memuat profil: $error');

      if (!_isDisposed) {
        _errorMessage = 'Profil gagal dimuat. Silakan coba lagi.';
      }
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void selectMeasurement(String id) {
    if (findById(id) == null) {
      throw ArgumentError('Profil tidak ditemukan.');
    }

    if (_activeMeasurementId == id) {
      return;
    }

    _activeMeasurementId = id;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

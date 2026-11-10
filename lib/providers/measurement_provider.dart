import 'package:flutter/foundation.dart';

import '../models/body_measurement.dart';
import '../repositories/measurement_repository.dart';

class MeasurementProvider extends ChangeNotifier {
  final MeasurementRepository _repository;

  List<BodyMeasurement> _measurements = const [];
  String? _activeMeasurementId;
  String? _errorMessage;
  String? _saveErrorMessage;

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isDisposed = false;

  MeasurementProvider(this._repository);

  List<BodyMeasurement> get measurements => _measurements;

  String? get activeMeasurementId => _activeMeasurementId;

  String? get errorMessage => _errorMessage;

  String? get saveErrorMessage => _saveErrorMessage;

  bool get isLoading => _isLoading;

  bool get isSaving => _isSaving;

  BodyMeasurement? get activeMeasurement {
    final id = _activeMeasurementId;
    return id == null ? null : findById(id);
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
    if (_isDisposed || _isLoading || _isSaving) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.getMeasurements();

      if (_isDisposed) return;

      _measurements = List<BodyMeasurement>.unmodifiable(result);

      final activeId = _activeMeasurementId;

      if (activeId != null && findById(activeId) == null) {
        _activeMeasurementId = null;
      }
    } catch (error) {
      if (_isDisposed) return;

      debugPrint('Gagal memuat profil: $error');

      _errorMessage =
          'Profil belum dapat dimuat. '
          'Periksa koneksi internet, lalu coba lagi.';
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void selectMeasurement(String id) {
    if (_isDisposed) return;

    if (findById(id) == null) {
      throw ArgumentError('Profil tidak ditemukan.');
    }

    if (_activeMeasurementId == id) return;

    _activeMeasurementId = id;
    notifyListeners();
  }

  void clearSaveError() {
    if (_isDisposed || _saveErrorMessage == null) return;

    _saveErrorMessage = null;
    notifyListeners();
  }

  Future<BodyMeasurement?> createMeasurement(
    BodyMeasurement measurement,
  ) async {
    if (_isDisposed || _isSaving) return null;

    if (_isLoading) {
      _saveErrorMessage =
          'Profil sedang dimuat. Tunggu sebentar, lalu coba lagi.';
      notifyListeners();
      return null;
    }

    _isSaving = true;
    _saveErrorMessage = null;
    notifyListeners();

    try {
      final saved = await _repository.createMeasurement(measurement);

      if (_isDisposed) return null;

      final updated = [
        saved,
        ..._measurements.where((item) => item.id != saved.id),
      ];

      updated.sort((a, b) {
        final dateOrder = b.measuredAt.compareTo(a.measuredAt);

        return dateOrder != 0 ? dateOrder : a.id.compareTo(b.id);
      });

      _measurements = List<BodyMeasurement>.unmodifiable(updated);
      _errorMessage = null;

      return saved;
    } on MeasurementSaveConflict {
      if (!_isDisposed) {
        _saveErrorMessage =
            'Profil ini sudah tersimpan dengan isian berbeda. '
            'Kembali ke daftar profil untuk memeriksanya.';
      }

      return null;
    } catch (error) {
      if (!_isDisposed) {
        debugPrint('Penyimpanan profil belum terkonfirmasi: $error');

        _saveErrorMessage =
            'Penyimpanan belum dapat dikonfirmasi. '
            'Periksa koneksi, lalu coba lagi. '
            'Isian tetap tersedia di formulir.';
      }

      return null;
    } finally {
      if (!_isDisposed) {
        _isSaving = false;
        notifyListeners();
      }
    }
  }

  Future<BodyMeasurement?> updateMeasurement(
    BodyMeasurement measurement,
  ) async {
    if (_isDisposed || _isSaving) return null;

    if (_isLoading) {
      _saveErrorMessage =
          'Profil sedang dimuat. Tunggu sebentar, lalu coba lagi.';
      notifyListeners();
      return null;
    }

    if (findById(measurement.id) == null) {
      _saveErrorMessage =
          'Profil tidak tersedia. Kembali ke daftar dan muat ulang.';
      notifyListeners();
      return null;
    }

    _isSaving = true;
    _saveErrorMessage = null;
    notifyListeners();

    try {
      final saved = await _repository.updateMeasurement(measurement);

      if (_isDisposed) return null;

      final updated = _measurements.map((item) {
        return item.id == saved.id ? saved : item;
      }).toList();

      updated.sort((a, b) {
        final dateOrder = b.measuredAt.compareTo(a.measuredAt);

        return dateOrder != 0 ? dateOrder : a.id.compareTo(b.id);
      });

      _measurements = List<BodyMeasurement>.unmodifiable(updated);
      _errorMessage = null;

      return saved;
    } on MeasurementUnavailable {
      if (!_isDisposed) {
        _saveErrorMessage =
            'Profil sudah tidak tersedia atau akses akun berubah. '
            'Kembali ke daftar dan muat ulang.';
      }

      return null;
    } catch (error) {
      if (!_isDisposed) {
        debugPrint('Perubahan profil belum terkonfirmasi: $error');

        _saveErrorMessage =
            'Perubahan belum dapat dikonfirmasi. '
            'Periksa koneksi, lalu coba simpan lagi. '
            'Isian tetap tersedia di formulir.';
      }

      return null;
    } finally {
      if (!_isDisposed) {
        _isSaving = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

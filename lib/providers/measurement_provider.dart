import 'package:flutter/foundation.dart';

import '../models/body_measurement.dart';
import '../repositories/measurement_repository.dart';

class MeasurementProvider extends ChangeNotifier {
  final MeasurementRepository _repository;

  List<BodyMeasurement> _measurements = const [];

  String? _activeMeasurementId;
  String? _errorMessage;
  String? _saveErrorMessage;
  String? _deleteErrorMessage;
  String? _deleteErrorId;

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _isDisposed = false;

  MeasurementProvider(this._repository);

  List<BodyMeasurement> get measurements => _measurements;
  String? get activeMeasurementId => _activeMeasurementId;
  String? get errorMessage => _errorMessage;
  String? get saveErrorMessage => _saveErrorMessage;
  String? get deleteErrorMessage => _deleteErrorMessage;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isDeleting => _isDeleting;

  bool get isBusy => _isLoading || _isSaving || _isDeleting;

  BodyMeasurement? get activeMeasurement {
    final id = _activeMeasurementId;
    return id == null ? null : findById(id);
  }

  BodyMeasurement? findById(String id) {
    for (final measurement in _measurements) {
      if (measurement.id == id) return measurement;
    }

    return null;
  }

  String? deleteErrorFor(String id) {
    return _deleteErrorId == id ? _deleteErrorMessage : null;
  }

  void _clearDeleteError() {
    _deleteErrorMessage = null;
    _deleteErrorId = null;
  }

  Future<void> loadMeasurements() async {
    if (_isDisposed || isBusy) return;

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

      final failedId = _deleteErrorId;

      if (failedId != null && findById(failedId) == null) {
        _clearDeleteError();
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

  void _storeMeasurement(BodyMeasurement saved) {
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

    if (_deleteErrorId == saved.id) {
      _clearDeleteError();
    }
  }

  Future<BodyMeasurement?> createMeasurement(BodyMeasurement measurement) {
    return _saveMeasurement(measurement, isUpdate: false);
  }

  Future<BodyMeasurement?> updateMeasurement(BodyMeasurement measurement) {
    return _saveMeasurement(measurement, isUpdate: true);
  }

  Future<BodyMeasurement?> _saveMeasurement(
    BodyMeasurement measurement, {
    required bool isUpdate,
  }) async {
    if (_isDisposed || _isSaving || _isDeleting) return null;

    if (_isLoading) {
      _saveErrorMessage =
          'Profil sedang dimuat. Tunggu sebentar, lalu coba lagi.';
      notifyListeners();
      return null;
    }

    if (isUpdate && findById(measurement.id) == null) {
      _saveErrorMessage =
          'Profil tidak tersedia. Kembali ke daftar dan muat ulang.';
      notifyListeners();
      return null;
    }

    _isSaving = true;
    _saveErrorMessage = null;
    notifyListeners();

    try {
      final saved = isUpdate
          ? await _repository.updateMeasurement(measurement)
          : await _repository.createMeasurement(measurement);

      if (_isDisposed) return null;

      _storeMeasurement(saved);
      return saved;
    } on MeasurementSaveConflict {
      if (!_isDisposed) {
        _saveErrorMessage =
            'Profil ini sudah tersimpan dengan isian berbeda. '
            'Kembali ke daftar profil untuk memeriksanya.';
      }

      return null;
    } on MeasurementUnavailable {
      if (!_isDisposed) {
        _saveErrorMessage =
            'Profil sudah tidak tersedia atau akses akun berubah. '
            'Kembali ke daftar dan muat ulang.';
      }

      return null;
    } catch (error) {
      if (!_isDisposed) {
        debugPrint('Penyimpanan profil belum terkonfirmasi: $error');

        final operation = isUpdate ? 'Perubahan' : 'Penyimpanan';

        _saveErrorMessage =
            '$operation belum dapat dikonfirmasi. '
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

  Future<bool> deleteMeasurement(String id) async {
    if (_isDisposed || _isSaving || _isDeleting) return false;

    if (_isLoading) {
      _deleteErrorId = id;
      _deleteErrorMessage =
          'Profil sedang dimuat. Tunggu sebentar, lalu coba lagi.';
      notifyListeners();
      return false;
    }

    if (findById(id) == null) {
      _deleteErrorId = id;
      _deleteErrorMessage = 'Profil tidak tersedia. Muat ulang daftar profil.';
      notifyListeners();
      return false;
    }

    _isDeleting = true;
    _deleteErrorId = id;
    _deleteErrorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteMeasurement(id);

      if (_isDisposed) return false;

      _measurements = List<BodyMeasurement>.unmodifiable(
        _measurements.where((item) => item.id != id),
      );

      if (_activeMeasurementId == id) {
        _activeMeasurementId = null;
      }

      _errorMessage = null;
      _clearDeleteError();

      return true;
    } on MeasurementUnavailable {
      if (!_isDisposed) {
        _deleteErrorMessage =
            'Profil mungkin sudah dihapus atau aksesnya berubah. '
            'Muat ulang profil untuk memeriksa data terbaru.';
      }

      return false;
    } catch (error) {
      if (!_isDisposed) {
        debugPrint('Penghapusan profil belum terkonfirmasi: $error');

        _deleteErrorMessage =
            'Penghapusan belum dapat dikonfirmasi. '
            'Periksa koneksi, lalu coba lagi atau muat ulang profil.';
      }

      return false;
    } finally {
      if (!_isDisposed) {
        _isDeleting = false;
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

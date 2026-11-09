import 'package:flutter/foundation.dart';

import '../models/measurement_guide.dart';
import '../repositories/measurement_guide_repository.dart';

class MeasurementGuideProvider extends ChangeNotifier {
  final MeasurementGuideRepository _repository;

  List<MeasurementGuide> _guides = const [];
  bool _isLoading = false;
  bool _isDisposed = false;
  String? _errorMessage;

  MeasurementGuideProvider(this._repository);

  List<MeasurementGuide> get guides => _guides;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadGuides() async {
    if (_isLoading || _isDisposed) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.getGuides();

      if (_isDisposed) return;

      _guides = List<MeasurementGuide>.unmodifiable(result);
    } catch (error) {
      if (_isDisposed) return;

      debugPrint('Gagal memuat panduan pengukuran: $error');

      _errorMessage =
          'Panduan belum dapat dimuat. '
          'Periksa koneksi internet, lalu coba lagi.';
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _repository.dispose();
    super.dispose();
  }
}

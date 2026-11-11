import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/body_measurement.dart';
import '../models/reviewed_size_chart.dart';
import '../models/size_analysis_result.dart';
import '../services/size_analysis_service.dart';
import 'measurement_provider.dart';
import 'screenshot_provider.dart';

class SizeAnalysisProvider extends ChangeNotifier {
  final MeasurementProvider measurements;
  final ScreenshotProvider screenshots;
  final SizeAnalysisService _service;
  SizeAnalysisProvider({
    required this.measurements,
    required this.screenshots,
    SizeAnalysisService? service,
  }) : _service = service ?? const SizeAnalysisService() {
    measurements.addListener(_onSourceChanged);
    screenshots.addListener(_onSourceChanged);
  }
  FitPreference _preference = FitPreference.regular;
  SizeAnalysisResult? _result;
  String? _errorMessage, _noticeMessage;
  bool _disposed = false;
  FitPreference get preference => _preference;
  SizeAnalysisResult? get result => _result;
  String? get errorMessage => _errorMessage;
  String? get noticeMessage => _noticeMessage;
  BodyMeasurement? get profile => measurements.activeMeasurement;
  ReviewedSizeChart? get chart => screenshots.reviewedChart;
  String? get blockedReason {
    if (measurements.isBusy || screenshots.isBusy) {
      return 'Tunggu pemrosesan data selesai.';
    }
    if (measurements.errorMessage != null) {
      return 'Profil belum dapat dikonfirmasi. Muat ulang daftar profil.';
    }
    if (profile == null) return 'Pilih profil tubuh aktif terlebih dahulu.';
    if (chart == null) return 'Periksa hasil pembacaan tabel terlebih dahulu.';
    return null;
  }

  bool get canAnalyze => blockedReason == null;
  void setPreference(FitPreference value) {
    if (_disposed || value == _preference) return;
    _preference = value;
    _result = null;
    _errorMessage = null;
    _noticeMessage = 'Preferensi berubah. Hitung kembali perbandingan ukuran.';
    notifyListeners();
  }

  bool analyze() {
    if (_disposed) return false;
    try {
      final reason = blockedReason;
      if (reason != null) throw FormatException(reason);
      _result = _service.analyze(
        id: const Uuid().v4(),
        profile: profile!,
        chart: chart!,
        preference: preference,
      );
      _errorMessage = null;
      _noticeMessage = null;
      notifyListeners();
      return true;
    } on FormatException catch (error) {
      _result = null;
      _errorMessage = error.message;
      notifyListeners();
      return false;
    }
  }

  void _onSourceChanged() {
    if (_disposed) return;
    final previous = _result;
    // Opening/cancelling the gallery alone does not change the source.
    if (previous != null &&
        (!identical(previous.profile, profile) ||
            !identical(previous.chart, chart) ||
            measurements.errorMessage != null)) {
      _result = null;
      _noticeMessage =
          'Data sumber berubah. Hitung kembali perbandingan ukuran.';
    }
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    measurements.removeListener(_onSourceChanged);
    screenshots.removeListener(_onSourceChanged);
    super.dispose();
  }
}

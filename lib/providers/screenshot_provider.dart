import 'package:flutter/foundation.dart';

import '../models/ocr_document.dart';
import '../models/reviewed_size_chart.dart';
import '../repositories/screenshot_repository.dart';
import '../services/size_chart_parser.dart';

enum ScreenshotPhase { idle, recovering, choosing, reading }

class ScreenshotProvider extends ChangeNotifier {
  final ScreenshotRepository _repository;

  ScreenshotProvider(this._repository);

  String? _imagePath;
  String _recognizedText = '';
  SizeChartDraft _draft = SizeChartDraft(rows: [], warnings: []);
  String? _errorMessage;
  String? _noticeMessage;

  ScreenshotPhase _phase = ScreenshotPhase.idle;
  ReviewedSizeChart? _reviewedChart;

  int _revision = 0;
  bool _initialized = false;
  bool _disposed = false;

  String? get imagePath => _imagePath;
  String get recognizedText => _recognizedText;
  String? get errorMessage => _errorMessage;
  String? get noticeMessage => _noticeMessage;
  ScreenshotPhase get phase => _phase;
  ReviewedSizeChart? get reviewedChart => _reviewedChart;
  int get revision => _revision;

  bool get isBusy => _phase != ScreenshotPhase.idle;
  bool get hasImage => _imagePath != null;

  SizeChartDraft buildChartDraft() {
    return _draft;
  }

  bool confirmChart(ReviewedSizeChart chart, {required int expectedRevision}) {
    if (_disposed ||
        isBusy ||
        expectedRevision != _revision ||
        chart.sourceImagePath != _imagePath ||
        chart.sourceOcrText != _recognizedText) {
      return false;
    }

    _reviewedChart = chart;
    notifyListeners();
    return true;
  }

  Future<bool> initialize() async {
    if (_disposed || _initialized || isBusy) {
      return false;
    }

    _initialized = true;
    return _importScreenshot(recovering: true);
  }

  Future<void> pickScreenshot() async {
    if (_disposed || isBusy) {
      return;
    }

    await _importScreenshot(recovering: false);
  }

  Future<bool> _importScreenshot({required bool recovering}) async {
    _phase = recovering ? ScreenshotPhase.recovering : ScreenshotPhase.choosing;
    notifyListeners();

    try {
      final path = recovering
          ? await _repository.recoverScreenshot()
          : await _repository.pickScreenshot();

      if (_disposed || path == null) {
        return false;
      }

      _imagePath = path;
      _recognizedText = '';
      _errorMessage = null;
      _noticeMessage = recovering
          ? 'Screenshot berhasil dipulihkan setelah aplikasi dibuka kembali. '
                'Periksa hasil pembacaannya.'
          : null;

      await _readImage(path);
      return !_disposed;
    } catch (error) {
      if (!_disposed) {
        debugPrint('Impor screenshot gagal: $error');

        if (recovering) {
          _errorMessage =
              'Screenshot sebelumnya belum dapat dipulihkan. '
              'Silakan pilih ulang gambar dari galeri.';
        } else {
          _errorMessage = hasImage
              ? 'Gambar baru belum berhasil dibuka. '
                    'Gambar sebelumnya masih ditampilkan. Coba pilih lagi.'
              : 'Screenshot belum berhasil dibuka. '
                    'Coba pilih gambar lagi.';
        }
      }

      return false;
    } finally {
      _finishOperation();
    }
  }

  Future<void> readAgain() async {
    final path = _imagePath;

    if (_disposed || isBusy || path == null) {
      return;
    }

    try {
      await _readImage(path);
    } finally {
      _finishOperation();
    }
  }

  Future<void> _readImage(String path) async {
    if (_disposed) {
      return;
    }

    _revision++;
    _reviewedChart = null;
    _phase = ScreenshotPhase.reading;
    _recognizedText = '';
    _draft = SizeChartDraft(rows: [], warnings: []);
    _errorMessage = null;
    notifyListeners();

    try {
      final repository = _repository;
      final document = repository is StructuredScreenshotRepository
          ? await (repository as StructuredScreenshotRepository).readDocument(
              path,
            )
          : OcrDocument(text: await repository.readText(path));

      if (_disposed) {
        return;
      }

      _recognizedText = document.text.trim();
      _draft = const SizeChartParser().parseDocument(document);

      if (_recognizedText.isEmpty) {
        _errorMessage =
            'Teks belum ditemukan. Gunakan screenshot yang lebih jelas '
            'atau isi tabel secara manual dari gambar.';
      }
    } catch (error) {
      if (!_disposed) {
        debugPrint('Pembacaan OCR gagal: $error');

        _errorMessage =
            'Teks belum dapat dibaca. '
            'Ketuk Baca ulang atau isi tabel secara manual dari gambar.';
      }
    }
  }

  void clearScreenshot() {
    if (_disposed || isBusy) {
      return;
    }

    _revision++;
    _reviewedChart = null;
    _imagePath = null;
    _recognizedText = '';
    _draft = SizeChartDraft(rows: [], warnings: []);
    _errorMessage = null;
    _noticeMessage = null;
    notifyListeners();
  }

  void _finishOperation() {
    if (_disposed) {
      return;
    }

    _phase = ScreenshotPhase.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

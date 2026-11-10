import 'package:flutter/foundation.dart';

import '../repositories/screenshot_repository.dart';

enum ScreenshotPhase { idle, recovering, choosing, reading }

class ScreenshotProvider extends ChangeNotifier {
  final ScreenshotRepository _repository;

  ScreenshotProvider(this._repository);

  String? _imagePath;
  String _recognizedText = '';
  String? _errorMessage;
  String? _noticeMessage;

  ScreenshotPhase _phase = ScreenshotPhase.idle;

  bool _initialized = false;
  bool _disposed = false;

  String? get imagePath => _imagePath;

  String get recognizedText => _recognizedText;

  String? get errorMessage => _errorMessage;

  String? get noticeMessage => _noticeMessage;

  ScreenshotPhase get phase => _phase;

  bool get isBusy => _phase != ScreenshotPhase.idle;

  bool get hasImage => _imagePath != null;

  Future<bool> initialize() async {
    if (_disposed || _initialized || isBusy) {
      return false;
    }

    _initialized = true;
    _phase = ScreenshotPhase.recovering;
    notifyListeners();

    try {
      final recoveredPath = await _repository.recoverScreenshot();

      if (_disposed || recoveredPath == null) {
        return false;
      }

      _imagePath = recoveredPath;
      _recognizedText = '';
      _errorMessage = null;
      _noticeMessage =
          'Screenshot berhasil dipulihkan setelah aplikasi dibuka kembali. '
          'Periksa hasil pembacaannya.';

      await _readImage(recoveredPath);

      return !_disposed;
    } catch (error) {
      if (!_disposed) {
        debugPrint('Pemulihan screenshot gagal: $error');

        _errorMessage =
            'Screenshot sebelumnya belum dapat dipulihkan. '
            'Silakan pilih ulang gambar dari galeri.';
      }

      return false;
    } finally {
      _finishOperation();
    }
  }

  Future<void> pickScreenshot() async {
    if (_disposed || isBusy) {
      return;
    }

    _phase = ScreenshotPhase.choosing;
    notifyListeners();

    try {
      final selectedPath = await _repository.pickScreenshot();

      if (_disposed || selectedPath == null) {
        return;
      }

      _imagePath = selectedPath;
      _recognizedText = '';
      _errorMessage = null;
      _noticeMessage = null;

      await _readImage(selectedPath);
    } catch (error) {
      if (!_disposed) {
        debugPrint('Pemilihan screenshot gagal: $error');

        _errorMessage = hasImage
            ? 'Gambar baru belum berhasil dibuka. '
                  'Gambar sebelumnya masih ditampilkan. Coba pilih lagi.'
            : 'Screenshot belum berhasil dibuka. '
                  'Coba pilih gambar lagi.';
      }
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

    _phase = ScreenshotPhase.reading;
    _recognizedText = '';
    _errorMessage = null;
    notifyListeners();

    try {
      final text = await _repository.readText(path);

      if (_disposed) {
        return;
      }

      _recognizedText = text.trim();

      if (_recognizedText.isEmpty) {
        _errorMessage =
            'Teks belum ditemukan. Gunakan screenshot yang lebih jelas '
            'dan pastikan tulisan pada tabel tidak terlalu kecil.';
      }
    } catch (error) {
      if (!_disposed) {
        debugPrint('Pembacaan OCR gagal: $error');

        _errorMessage =
            'Teks belum dapat dibaca. '
            'Ketuk Baca ulang atau pilih gambar lain.';
      }
    }
  }

  void clearScreenshot() {
    if (_disposed || isBusy) {
      return;
    }

    _imagePath = null;
    _recognizedText = '';
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

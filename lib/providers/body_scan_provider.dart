import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import '../models/body_scan_result.dart';
import '../repositories/body_camera_repository.dart';

enum BodyScanPhase {
  intro,
  opening,
  camera,
  capturing,
  review,
  result,
  paused,
  error,
}

class BodyScanProvider extends ChangeNotifier {
  final BodyCameraRepository camera;
  BodyScanProvider(this.camera);
  BodyScanPhase _phase = BodyScanPhase.intro;
  String? _photoPath, _errorMessage;
  BodyScanResult? _result;
  Future<void> _tail = Future.value();
  int _epoch = 0;
  bool _disposed = false, _foreground = true;

  BodyScanPhase get phase => _phase;
  String? get photoPath => _photoPath;
  String? get errorMessage => _errorMessage;
  BodyScanResult? get result => _result;
  Future<void> get settled => _tail;
  bool get isBusy =>
      _phase == BodyScanPhase.opening || _phase == BodyScanPhase.capturing;
  bool _current(int ticket) => !_disposed && _foreground && ticket == _epoch;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _enqueue(Future<void> Function() action) {
    final task = _tail.then((_) => action());
    _tail = task.catchError((Object _) {
      debugPrint('Operasi pembersihan kamera belum selesai.');
    });
    return task;
  }

  Future<void> _release() async {
    try {
      await camera.release();
    } catch (_) {
      debugPrint('Kamera belum berhasil dilepas.');
    }
  }

  Future<void> _discard(String path) async {
    try {
      await camera.discardPhoto(path);
    } catch (_) {
      debugPrint('Foto sementara belum berhasil dibersihkan.');
    }
  }

  String _message(Object error) {
    if (error is CameraException) {
      if ([
        'CameraAccessDenied',
        'CameraAccessDeniedWithoutPrompt',
        'CameraAccessRestricted',
      ].contains(error.code)) {
        return 'Izin kamera belum tersedia. Izinkan kamera melalui pengaturan aplikasi, lalu coba lagi, atau isi ukuran secara manual.';
      }
      if (error.code == 'NoCamera') {
        return 'Kamera tidak tersedia pada perangkat ini. Anda tetap dapat mengisi ukuran secara manual.';
      }
    }
    return 'Kamera belum dapat digunakan. Coba lagi atau isi ukuran secara manual.';
  }

  Future<void> openCamera({bool switchLens = false}) {
    if (_disposed || !_foreground || isBusy) return Future.value();
    if (switchLens && (_phase != BodyScanPhase.camera || !camera.canSwitch)) {
      return Future.value();
    }
    final ticket = ++_epoch;
    final oldPhoto = _photoPath;
    _photoPath = null;
    _result = null;
    _errorMessage = null;
    _phase = BodyScanPhase.opening;
    _notify();
    return _enqueue(() async {
      if (oldPhoto != null) await _discard(oldPhoto);
      if (!_current(ticket)) return;
      try {
        if (switchLens) {
          await camera.switchCamera();
        } else {
          await camera.initialize();
        }
        if (!_current(ticket)) {
          await _release();
          return;
        }
        _phase = BodyScanPhase.camera;
      } catch (error) {
        await _release();
        if (!_current(ticket)) return;
        _errorMessage = _message(error);
        _phase = BodyScanPhase.error;
      }
      _notify();
    });
  }

  Future<void> capture() {
    if (_disposed || !_foreground || _phase != BodyScanPhase.camera) {
      return Future.value();
    }
    final ticket = ++_epoch;
    _phase = BodyScanPhase.capturing;
    _errorMessage = null;
    _notify();
    return _enqueue(() async {
      if (!_current(ticket)) return;
      String? path;
      try {
        path = await camera.capture();
        await _release();
        if (!_current(ticket)) {
          await _discard(path);
          return;
        }
        _photoPath = path;
        _phase = BodyScanPhase.review;
      } catch (error) {
        if (path != null) await _discard(path);
        await _release();
        if (!_current(ticket)) return;
        _errorMessage = _message(error);
        _phase = BodyScanPhase.error;
      }
      _notify();
    });
  }

  void showResult() {
    if (_disposed ||
        !_foreground ||
        _phase != BodyScanPhase.review ||
        _photoPath == null) {
      return;
    }
    _result = BodyScanResult.demo(
      photoPath: _photoPath!,
      createdAt: DateTime.now(),
    );
    _phase = BodyScanPhase.result;
    _notify();
  }

  Future<void> onLifecycleChanged(AppLifecycleState state) {
    // Dialog izin dapat membuat activity inactive ketika initialize masih berjalan.
    if (state == AppLifecycleState.inactive &&
        _phase == BodyScanPhase.opening) {
      return Future.value();
    }
    return setForeground(state == AppLifecycleState.resumed);
  }

  Future<void> setForeground(bool foreground) {
    if (_disposed || _foreground == foreground) return Future.value();
    _foreground = foreground;
    if (foreground) {
      if (_phase == BodyScanPhase.paused) return openCamera();
      return Future.value();
    }
    ++_epoch;
    if ([
      BodyScanPhase.opening,
      BodyScanPhase.camera,
      BodyScanPhase.capturing,
    ].contains(_phase)) {
      _phase = BodyScanPhase.paused;
    }
    _notify();
    return _enqueue(_release);
  }

  @override
  void dispose() {
    _disposed = true;
    ++_epoch;
    _photoPath = null;
    _result = null;
    unawaited(_enqueue(camera.close));
    super.dispose();
  }
}

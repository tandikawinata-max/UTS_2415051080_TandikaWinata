import 'dart:io';
import 'package:camera/camera.dart';

/// Operasi hardware dipanggil berurutan oleh BodyScanProvider.
class BodyCameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  final Set<String> _ownedPhotos = {};
  int _index = 0;

  CameraController? get controller => _controller;
  bool get canSwitch => _cameras.length > 1;

  Future<void> initialize() async {
    await release();
    _cameras = await availableCameras();
    if (_cameras.isEmpty) {
      throw CameraException('NoCamera', 'No camera available');
    }
    _index %= _cameras.length;
    final next = CameraController(
      _cameras[_index],
      ResolutionPreset.medium,
      enableAudio: false,
    );
    try {
      await next.initialize();
      _controller = next;
    } catch (_) {
      await next.dispose();
      rethrow;
    }
  }

  Future<void> switchCamera() async {
    if (!canSwitch) return;
    _index = (_index + 1) % _cameras.length;
    await initialize();
  }

  Future<String> capture() async {
    final current = _controller;
    if (current == null || !current.value.isInitialized) {
      throw CameraException('NotReady', 'Camera is not ready');
    }
    final image = await current.takePicture();
    _ownedPhotos.add(image.path);
    return image.path;
  }

  Future<void> release() async {
    final previous = _controller;
    _controller = null;
    await previous?.dispose();
  }

  Future<void> discardPhoto(String path) async {
    // Hanya file yang dihasilkan kamera sesi ini yang boleh dihapus.
    if (!_ownedPhotos.contains(path)) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
    _ownedPhotos.remove(path);
  }

  Future<void> close() async {
    try {
      await release();
    } finally {
      for (final path in _ownedPhotos.toList()) {
        try {
          await discardPhoto(path);
        } on FileSystemException {
          // Cache dapat dibersihkan OS jika file sedang tidak dapat dihapus.
        }
      }
    }
  }
}

import 'package:camera/camera.dart';
import '../services/body_camera_service.dart';

abstract class BodyCameraRepository {
  CameraController? get controller;
  bool get canSwitch;
  Future<void> initialize();
  Future<void> switchCamera();
  Future<String> capture();
  Future<void> release();
  Future<void> discardPhoto(String path);
  Future<void> close();
}

class DeviceBodyCameraRepository implements BodyCameraRepository {
  final BodyCameraService _service;
  DeviceBodyCameraRepository({BodyCameraService? service})
    : _service = service ?? BodyCameraService();
  @override
  CameraController? get controller => _service.controller;
  @override
  bool get canSwitch => _service.canSwitch;
  @override
  Future<void> initialize() => _service.initialize();
  @override
  Future<void> switchCamera() => _service.switchCamera();
  @override
  Future<String> capture() => _service.capture();
  @override
  Future<void> release() => _service.release();
  @override
  Future<void> discardPhoto(String path) => _service.discardPhoto(path);
  @override
  Future<void> close() => _service.close();
}

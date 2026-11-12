import 'dart:async';
import 'package:camera/camera.dart';
import 'package:usize/repositories/body_camera_repository.dart';

class FakeBodyCameraRepository implements BodyCameraRepository {
  Object? openError, captureError;
  Completer<void>? opening;
  Completer<String>? capturing;
  int initializeCalls = 0,
      captureCalls = 0,
      releaseCalls = 0,
      switchCalls = 0,
      closeCalls = 0;
  final owned = <String>{};
  final discarded = <String>[];
  final events = <String>[];
  @override
  CameraController? get controller => null;
  @override
  bool canSwitch = true;
  @override
  Future<void> initialize() async {
    initializeCalls++;
    events.add('open-start');
    if (opening != null) await opening!.future;
    if (openError != null) throw openError!;
    events.add('open-done');
  }

  @override
  Future<void> switchCamera() async {
    switchCalls++;
    await initialize();
  }

  @override
  Future<String> capture() async {
    captureCalls++;
    if (captureError != null) throw captureError!;
    final path = capturing == null
        ? '/temporary-body-$captureCalls.jpg'
        : await capturing!.future;
    owned.add(path);
    return path;
  }

  @override
  Future<void> release() async {
    releaseCalls++;
    events.add('release');
  }

  @override
  Future<void> discardPhoto(String path) async {
    discarded.add(path);
    owned.remove(path);
  }

  @override
  Future<void> close() async {
    closeCalls++;
    await release();
    for (final path in owned.toList()) {
      await discardPhoto(path);
    }
  }
}

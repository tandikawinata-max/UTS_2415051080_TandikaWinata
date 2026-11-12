import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usize/models/body_scan_result.dart';
import 'package:usize/providers/body_scan_provider.dart';
import 'body_camera_fixtures.dart';

void main() {
  test(
    'demo numbers are fixed across photos and contain no weight prediction',
    () {
      final a = BodyScanResult.demo(photoPath: '/a', createdAt: DateTime(2026));
      final b = BodyScanResult.demo(photoPath: '/b', createdAt: DateTime(2027));
      expect(a.sampleProfile.chestCm, 94);
      expect(b.sampleProfile.chestCm, 94);
      expect(a.sampleProfile.waistCm, 80);
      expect(a.sampleProfile.hipCm, 96);
      expect(a.sampleProfile.shoulderWidthCm, 42);
      expect(a.sampleProfile.heightCm, isNull);
      expect(a.sampleProfile.weightKg, isNull);
      expect(a.sampleProfile.label, contains('simulasi'));
    },
  );

  test(
    'duplicate capture is ignored; retake clears the sample and deletes the old photo',
    () async {
      final camera = FakeBodyCameraRepository();
      final state = BodyScanProvider(camera);
      await state.openCamera();
      camera.capturing = Completer<String>();
      final capture = state.capture();
      await state.capture();
      await state.openCamera(switchLens: true);
      await Future<void>.delayed(Duration.zero);
      expect(camera.captureCalls, 1);
      expect(camera.switchCalls, 0);
      camera.capturing!.complete('/first.jpg');
      await capture;
      expect(state.phase, BodyScanPhase.review);
      expect(camera.releaseCalls, greaterThan(0));
      state.showResult();
      expect(state.result!.sampleProfile.chestCm, 94);
      await state.openCamera();
      expect(state.result, isNull);
      expect(state.photoPath, isNull);
      expect(camera.discarded, contains('/first.jpg'));
      state.dispose();
      await state.settled;
      expect(camera.owned, isEmpty);
    },
  );

  for (final entry in [
    (CameraException('CameraAccessDenied', 'technical detail'), 'Izin kamera'),
    (CameraException('NoCamera', 'technical detail'), 'Kamera tidak tersedia'),
    (StateError('technical detail'), 'Kamera belum dapat digunakan'),
  ]) {
    test(
      'camera failure ${entry.$2} exposes retry without technical details',
      () async {
        final camera = FakeBodyCameraRepository()..openError = entry.$1;
        final state = BodyScanProvider(camera);
        await state.openCamera();
        expect(state.phase, BodyScanPhase.error);
        expect(state.errorMessage, contains(entry.$2));
        expect(state.errorMessage, isNot(contains('technical detail')));
        camera.openError = null;
        await state.openCamera();
        expect(state.phase, BodyScanPhase.camera);
        state.dispose();
        await state.settled;
      },
    );
  }

  test(
    'background and resume serialize release after pending initialize',
    () async {
      final camera = FakeBodyCameraRepository()..opening = Completer<void>();
      final state = BodyScanProvider(camera);
      final open = state.openCamera();
      await Future<void>.delayed(Duration.zero);
      final paused = state.setForeground(false);
      final resumed = state.setForeground(true);
      expect(state.phase, BodyScanPhase.opening);
      camera.opening!.complete();
      await Future.wait([open, paused, resumed]);
      expect(camera.initializeCalls, 2);
      expect(state.phase, BodyScanPhase.camera);
      expect(
        camera.events.indexOf('release'),
        greaterThan(camera.events.indexOf('open-done')),
      );
      state.dispose();
      await state.settled;
    },
  );

  test('photo completing while backgrounded is discarded', () async {
    final camera = FakeBodyCameraRepository()..capturing = Completer<String>();
    final state = BodyScanProvider(camera);
    await state.openCamera();
    final capture = state.capture();
    await Future<void>.delayed(Duration.zero);
    final paused = state.setForeground(false);
    camera.capturing!.complete('/late.jpg');
    await Future.wait([capture, paused]);
    expect(state.phase, BodyScanPhase.paused);
    expect(state.photoPath, isNull);
    expect(camera.discarded, contains('/late.jpg'));
    await state.setForeground(true);
    expect(state.phase, BodyScanPhase.camera);
    state.dispose();
    await state.settled;
  });

  test(
    'photo completing after route disposal is deleted and cannot notify',
    () async {
      final camera = FakeBodyCameraRepository()
        ..capturing = Completer<String>();
      final state = BodyScanProvider(camera);
      await state.openCamera();
      final capture = state.capture();
      await Future<void>.delayed(Duration.zero);
      state.dispose();
      camera.capturing!.complete('/closed.jpg');
      await capture;
      await state.settled;
      expect(state.result, isNull);
      expect(camera.owned, isEmpty);
      expect(camera.discarded, contains('/closed.jpg'));
      expect(camera.closeCalls, 1);
    },
  );

  test(
    'closing during initialize releases hardware after it finishes',
    () async {
      final camera = FakeBodyCameraRepository()..opening = Completer<void>();
      final state = BodyScanProvider(camera);
      final open = state.openCamera();
      await Future<void>.delayed(Duration.zero);
      state.dispose();
      camera.opening!.complete();
      await open;
      await state.settled;
      expect(camera.releaseCalls, greaterThan(0));
      expect(camera.closeCalls, 1);
    },
  );

  test(
    'background in result keeps the photo and does not reopen hardware',
    () async {
      final camera = FakeBodyCameraRepository();
      final state = BodyScanProvider(camera);
      await state.openCamera();
      await state.capture();
      state.showResult();
      await state.setForeground(false);
      await state.setForeground(true);
      expect(state.phase, BodyScanPhase.result);
      expect(state.photoPath, isNotNull);
      expect(camera.initializeCalls, 1);
      state.dispose();
      await state.settled;
      expect(camera.owned, isEmpty);
    },
  );

  test(
    'permission dialog inactive/resumed does not restart initialize',
    () async {
      final camera = FakeBodyCameraRepository()..opening = Completer<void>();
      final state = BodyScanProvider(camera);
      final open = state.openCamera();
      await state.onLifecycleChanged(AppLifecycleState.inactive);
      await state.onLifecycleChanged(AppLifecycleState.resumed);
      camera.opening!.complete();
      await open;
      expect(camera.initializeCalls, 1);
      expect(state.phase, BodyScanPhase.camera);
      state.dispose();
      await state.settled;
    },
  );

  test(
    'capture failure releases hardware and allows another attempt',
    () async {
      final camera = FakeBodyCameraRepository()
        ..captureError = StateError('capture failed');
      final state = BodyScanProvider(camera);
      await state.openCamera();
      await state.capture();
      expect(state.phase, BodyScanPhase.error);
      expect(state.photoPath, isNull);
      camera.captureError = null;
      await state.openCamera();
      await state.capture();
      expect(state.phase, BodyScanPhase.review);
      state.dispose();
      await state.settled;
    },
  );

  test('switch camera is available only while preview is ready', () async {
    final camera = FakeBodyCameraRepository();
    final state = BodyScanProvider(camera);
    await state.openCamera(switchLens: true);
    expect(camera.switchCalls, 0);
    await state.openCamera();
    await state.openCamera(switchLens: true);
    expect(camera.switchCalls, 1);
    await state.capture();
    await state.openCamera(switchLens: true);
    expect(camera.switchCalls, 1);
    state.dispose();
    await state.settled;
  });
}

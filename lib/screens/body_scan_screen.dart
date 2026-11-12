import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../providers/body_scan_provider.dart';
import '../repositories/body_camera_repository.dart';
import '../repositories/screenshot_repository.dart';
import '../widgets/body_demo_banner.dart';
import '../widgets/body_position_guide.dart';
import 'demo_analysis_session.dart';

enum BodyScanAction { enterManually }

class BodyScanScreen extends StatefulWidget {
  final BodyCameraRepository? cameraRepository;
  final ScreenshotRepository? demoScreenshotRepository;
  const BodyScanScreen({
    super.key,
    this.cameraRepository,
    this.demoScreenshotRepository,
  });
  @override
  State<BodyScanScreen> createState() => _BodyScanScreenState();
}

class _BodyScanScreenState extends State<BodyScanScreen>
    with WidgetsBindingObserver {
  late final BodyScanProvider _state;
  bool _openingAnalysis = false;
  @override
  void initState() {
    super.initState();
    _state = BodyScanProvider(
      widget.cameraRepository ?? DeviceBodyCameraRepository(),
    );
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    unawaited(_state.onLifecycleChanged(state));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _state.dispose();
    super.dispose();
  }

  Future<void> _openAnalysis() async {
    final sample = _state.result?.sampleProfile;
    if (sample == null || _openingAnalysis) return;
    setState(() => _openingAnalysis = true);
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => DemoAnalysisSession(
            sampleProfile: sample,
            screenshotRepository: widget.demoScreenshotRepository,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _openingAnalysis = false);
    }
  }

  Widget _preview() {
    final controller = _state.camera.controller;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Colors.black),
            if (controller != null) Center(child: CameraPreview(controller)),
            const BodyPositionGuide(),
            const Positioned(
              left: 12,
              top: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'DEMO',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photo() => ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: Image.file(
      File(_state.photoPath!),
      height: 300,
      fit: BoxFit.contain,
      cacheWidth: 1200,
      errorBuilder: (_, error, stack) => const Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Foto tidak dapat ditampilkan. Ambil ulang untuk mencoba lagi.',
        ),
      ),
    ),
  );

  List<Widget> _content(BuildContext context) {
    switch (_state.phase) {
      case BodyScanPhase.intro:
        return [
          const Icon(Icons.accessibility_new, size: 72),
          const SizedBox(height: 16),
          Text(
            'Coba ukur tubuh dengan kamera',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          const Text(
            'Posisikan seluruh tubuh di dalam bingkai, menghadap kamera, dengan pencahayaan cukup. Minta bantuan untuk mengambil foto bila diperlukan.',
          ),
          const SizedBox(height: 12),
          const Text(
            'Kamera mengambil foto sungguhan. Siluet hanya panduan posisi statis; angka hasil masih berupa contoh. Foto dipakai sementara di perangkat.',
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            key: const ValueKey('openBodyCamera'),
            onPressed: _state.openCamera,
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Buka kamera'),
          ),
        ];
      case BodyScanPhase.opening:
      case BodyScanPhase.capturing:
        return [
          const LinearProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            _state.phase == BodyScanPhase.opening
                ? 'Menyiapkan kamera...'
                : 'Mengambil foto...',
          ),
        ];
      case BodyScanPhase.camera:
        return [
          _preview(),
          const SizedBox(height: 12),
          const Text(
            'Panduan posisi statis · Belum mendeteksi pose secara otomatis.',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const ValueKey('captureBodyPhoto'),
            onPressed: _state.capture,
            icon: const Icon(Icons.camera),
            label: const Text('Ambil foto'),
          ),
          if (_state.camera.canSwitch)
            TextButton.icon(
              key: const ValueKey('switchBodyCamera'),
              onPressed: () => _state.openCamera(switchLens: true),
              icon: const Icon(Icons.flip_camera_android_outlined),
              label: const Text('Ganti kamera'),
            ),
        ];
      case BodyScanPhase.review:
        return [
          _photo(),
          const SizedBox(height: 16),
          const Text('Periksa foto sebelum melanjutkan demonstrasi.'),
          const SizedBox(height: 12),
          FilledButton(
            key: const ValueKey('showBodyDemoResult'),
            onPressed: _state.showResult,
            child: const Text('Lihat hasil demo'),
          ),
          TextButton(
            key: const ValueKey('retakeBodyPhoto'),
            onPressed: _state.openCamera,
            child: const Text('Ambil ulang'),
          ),
        ];
      case BodyScanPhase.result:
        final profile = _state.result!.sampleProfile;
        return [
          Text(
            'Contoh hasil ukuran tubuh',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lingkar dada: ${profile.chestCm.toStringAsFixed(0)} cm',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Lingkar pinggang: ${profile.waistCm!.toStringAsFixed(0)} cm',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Lingkar pinggul: ${profile.hipCm!.toStringAsFixed(0)} cm',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Lebar bahu: ${profile.shoulderWidthCm!.toStringAsFixed(0)} cm',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Gunakan angka contoh ini untuk mencoba analisis dari screenshot tabel ukuran pakaian.',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const ValueKey('tryBodyDemoAnalysis'),
            onPressed: _openingAnalysis ? null : _openAnalysis,
            icon: const Icon(Icons.compare_arrows),
            label: const Text('Coba analisis demo'),
          ),
          TextButton(
            key: const ValueKey('retakeBodyPhoto'),
            onPressed: _state.openCamera,
            child: const Text('Ambil ulang'),
          ),
        ];
      case BodyScanPhase.paused:
        return [
          const Icon(Icons.pause_circle_outline, size: 48),
          const SizedBox(height: 12),
          const Text('Kamera dijeda saat aplikasi tidak aktif.'),
        ];
      case BodyScanPhase.error:
        return [
          const Icon(Icons.no_photography_outlined, size: 48),
          const SizedBox(height: 12),
          Text(_state.errorMessage!, key: const ValueKey('bodyCameraError')),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            key: const ValueKey('retryBodyCamera'),
            onPressed: _state.openCamera,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba lagi'),
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _state,
    builder: (context, _) => Scaffold(
      appBar: AppBar(title: const Text('Ukur tubuh — Demo')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                const BodyDemoBanner(),
                const SizedBox(height: 16),
                ..._content(context),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  key: const ValueKey('enterActualMeasurements'),
                  onPressed: () =>
                      Navigator.of(context).pop(BodyScanAction.enterManually),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Isi ukuran sebenarnya'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

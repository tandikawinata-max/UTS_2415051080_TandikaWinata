import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/body_measurement.dart';
import '../providers/measurement_provider.dart';
import '../providers/screenshot_provider.dart';
import '../providers/size_analysis_provider.dart';
import '../repositories/demo_measurement_repository.dart';
import '../repositories/screenshot_repository.dart';
import 'ocr_test_screen.dart';

/// Seluruh provider dimiliki route demo; tidak mengganti provider akun pengguna.
class DemoAnalysisSession extends StatefulWidget {
  final BodyMeasurement sampleProfile;
  final ScreenshotRepository? screenshotRepository;
  const DemoAnalysisSession({
    super.key,
    required this.sampleProfile,
    this.screenshotRepository,
  });
  @override
  State<DemoAnalysisSession> createState() => _DemoAnalysisSessionState();
}

class _DemoAnalysisSessionState extends State<DemoAnalysisSession> {
  late final MeasurementProvider _measurements;
  late final ScreenshotProvider _screenshots;
  late final SizeAnalysisProvider _analysis;
  late final Future<void> _ready;
  @override
  void initState() {
    super.initState();
    _measurements = MeasurementProvider(
      DemoMeasurementRepository(initialMeasurements: [widget.sampleProfile]),
    );
    _screenshots = ScreenshotProvider(
      widget.screenshotRepository ?? DeviceScreenshotRepository(),
    );
    _analysis = SizeAnalysisProvider(
      measurements: _measurements,
      screenshots: _screenshots,
      isDemo: true,
    );
    _ready = _load();
  }

  Future<void> _load() async {
    await _measurements.loadMeasurements();
    if (mounted) _measurements.selectMeasurement(widget.sampleProfile.id);
  }

  @override
  void dispose() {
    _analysis.dispose();
    _screenshots.dispose();
    _measurements.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _ready,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return Scaffold(
          appBar: AppBar(title: const Text('Analisis demo')),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<MeasurementProvider>.value(
            value: _measurements,
          ),
          ChangeNotifierProvider<ScreenshotProvider>.value(value: _screenshots),
          ChangeNotifierProvider<SizeAnalysisProvider>.value(value: _analysis),
        ],
        child: const OcrTestScreen(),
      );
    },
  );
}

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:usize/providers/analysis_history_provider.dart';
import 'package:usize/providers/measurement_provider.dart';
import 'package:usize/providers/screenshot_provider.dart';
import 'package:usize/providers/size_analysis_provider.dart';
import 'package:usize/repositories/demo_measurement_repository.dart';
import 'package:usize/screens/body_scan_screen.dart';
import 'package:usize/screens/main_navigation_screen.dart';
import 'package:usize/screens/measurement_form_screen.dart';
import 'package:usize/theme/usize_theme.dart';
import 'package:usize/widgets/analysis_save_card.dart';
import 'body_camera_fixtures.dart';
import 'history_fixtures.dart';
import 'scroll_helpers.dart';

Future<void> tapKey(
  WidgetTester tester,
  String key, {
  double delta = 200,
}) async {
  final target = find.byKey(ValueKey(key));
  await reveal(tester, target, delta: delta);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  for (final layout in [(390.0, 1.0), (320.0, 2.0), (1024.0, 1.0)]) {
    testWidgets(
      'camera demo to screenshot analysis stays isolated at $layout',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(layout.$1, 1000);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final camera = FakeBodyCameraRepository();
        final account = MeasurementProvider(
          DemoMeasurementRepository(
            initialMeasurements: [historyProfile(chest: 110)],
          ),
        );
        final historyRepo = ControlledHistoryRepository();
        await historyRepo.save(historyDraft());
        final history = AnalysisHistoryProvider(historyRepo);
        final screenshot = ScreenshotProvider(HistoryScreenshotRepository());
        final analysis = SizeAnalysisProvider(
          measurements: account,
          screenshots: screenshot,
        );
        addTearDown(account.dispose);
        addTearDown(history.dispose);
        addTearDown(screenshot.dispose);
        addTearDown(analysis.dispose);
        await account.loadMeasurements();
        account.selectMeasurement('profile-a');
        await history.loadHistory();
        await screenshot.pickScreenshot();
        final originalPath = screenshot.imagePath;
        final originalChart = screenshot.buildChartDraft();
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<MeasurementProvider>.value(value: account),
              ChangeNotifierProvider<AnalysisHistoryProvider>.value(
                value: history,
              ),
              ChangeNotifierProvider<ScreenshotProvider>.value(
                value: screenshot,
              ),
              ChangeNotifierProvider<SizeAnalysisProvider>.value(
                value: analysis,
              ),
            ],
            child: MaterialApp(
              theme: UsizeTheme.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(layout.$2)),
                child: child!,
              ),
              home: Builder(
                builder: (context) => Scaffold(
                  body: Center(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => BodyScanScreen(
                            cameraRepository: camera,
                            demoScreenshotRepository:
                                HistoryScreenshotRepository(),
                          ),
                        ),
                      ),
                      child: const Text('Mulai demo'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Mulai demo'));
        await tester.pumpAndSettle();
        await tapKey(tester, 'openBodyCamera');
        await tapKey(tester, 'captureBodyPhoto');
        expect(camera.releaseCalls, greaterThan(0));
        await tapKey(tester, 'retakeBodyPhoto');
        expect(camera.discarded, contains('/temporary-body-1.jpg'));
        await tapKey(tester, 'captureBodyPhoto');
        await tapKey(tester, 'showBodyDemoResult');
        await reveal(tester, find.text('Lingkar dada: 94 cm'), delta: -200);
        expect(find.text('Lingkar dada: 94 cm'), findsOneWidget);
        await tapKey(tester, 'tryBodyDemoAnalysis');
        expect(find.text('Analisis screenshot — Demo'), findsOneWidget);
        expect(find.text('Pilih profil tubuh'), findsNothing);
        await tapKey(tester, 'pickScreenshot');
        await tapKey(tester, 'openSizeAnalysis');
        await reveal(
          tester,
          find.byKey(const ValueKey('analysisRecommendation')),
        );
        expect(find.text('Kandidat: M'), findsOneWidget);
        expect(find.byType(AnalysisSaveCard), findsNothing);
        expect(find.byKey(const ValueKey('saveAnalysis')), findsNothing);
        expect(find.text('Pilih atau kelola profil'), findsNothing);
        await tester.pageBack();
        await tester.pumpAndSettle();
        await tester.pageBack();
        await tester.pumpAndSettle();
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(account.measurements, hasLength(1));
        expect(account.activeMeasurement!.chestCm, 110);
        expect(account.activeMeasurement!.id, 'profile-a');
        expect(screenshot.imagePath, originalPath);
        expect(identical(screenshot.buildChartDraft(), originalChart), isTrue);
        expect(history.items, hasLength(1));
        expect(historyRepo.saveCalls, 1);
        expect(camera.owned, isEmpty);
        expect(camera.closeCalls, 1);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'denied camera permits manual fallback without a sample profile',
    (tester) async {
      final camera = FakeBodyCameraRepository()
        ..openError = CameraException('CameraAccessDenied', 'denied');
      BodyScanAction? action;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () async {
                  action = await Navigator.of(context).push<BodyScanAction>(
                    MaterialPageRoute(
                      builder: (_) => BodyScanScreen(cameraRepository: camera),
                    ),
                  );
                },
                child: const Text('Mulai'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Mulai'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'openBodyCamera');
      expect(find.byKey(const ValueKey('bodyCameraError')), findsOneWidget);
      await tapKey(tester, 'enterActualMeasurements');
      expect(action, BodyScanAction.enterManually);
      expect(camera.captureCalls, 0);
      expect(camera.closeCalls, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'dashboard fallback opens a blank form; form fallback preserves its draft',
    (tester) async {
      final measurements = MeasurementProvider(
        DemoMeasurementRepository(initialMeasurements: [historyProfile()]),
      );
      addTearDown(measurements.dispose);
      await measurements.loadMeasurements();
      await tester.pumpWidget(
        ChangeNotifierProvider<MeasurementProvider>.value(
          value: measurements,
          child: MaterialApp(
            theme: UsizeTheme.light,
            home: MainNavigationScreen(
              historyRepository: ControlledHistoryRepository(),
              screenshotRepository: HistoryScreenshotRepository(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tapKey(tester, 'openBodyScan');
      await tapKey(tester, 'enterActualMeasurements');
      expect(find.byType(MeasurementFormScreen), findsOneWidget);
      final name = find.byKey(const ValueKey('label'));
      final chest = find.byKey(const ValueKey('chest'));
      expect(tester.widget<TextFormField>(name).controller!.text, isEmpty);
      expect(tester.widget<TextFormField>(chest).controller!.text, isEmpty);
      await tester.enterText(name, 'Draf asli');
      await tester.enterText(chest, '105');
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tapKey(tester, 'openBodyScan', delta: -200);
      await tapKey(tester, 'enterActualMeasurements');
      expect(find.byType(MeasurementFormScreen), findsOneWidget);
      expect(tester.widget<TextFormField>(name).controller!.text, 'Draf asli');
      expect(tester.widget<TextFormField>(chest).controller!.text, '105');
      expect(measurements.measurements, hasLength(1));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

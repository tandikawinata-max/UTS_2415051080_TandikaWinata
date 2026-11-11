import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:usize/models/body_measurement.dart';
import 'package:usize/models/ocr_document.dart';
import 'package:usize/providers/measurement_provider.dart';
import 'package:usize/repositories/demo_measurement_repository.dart';
import 'package:usize/repositories/screenshot_repository.dart';
import 'package:usize/screens/main_navigation_screen.dart';
import 'package:usize/screens/size_chart_review_screen.dart';

import 'scroll_helpers.dart';

class StructuredRepository
    implements ScreenshotRepository, StructuredScreenshotRepository {
  final bool ambiguous;
  StructuredRepository({this.ambiguous = false});
  @override
  Future<String?> pickScreenshot() async => '/chart.png';
  @override
  Future<String?> recoverScreenshot() async => null;
  @override
  Future<String> readText(String path) async =>
      throw StateError('Structured reader should be used');
  @override
  Future<OcrDocument> readDocument(String path) async {
    OcrToken t(String text, double x, double y) => OcrToken(
      text: text,
      left: x - 15,
      right: x + 15,
      top: y - 8,
      bottom: y + 8,
    );
    final heading = ambiguous ? 'Dada' : 'Lingkar dada';
    return OcrDocument(
      text:
          'UKURAN PAKAIAN\nSIZE $heading Lingkar pinggang cm\nM 100 86\nL 104 90',
      tokens: [
        t('90', 280, 100),
        t('M', 40, 60),
        t('SIZE', 40, 20),
        t(heading, 160, 20),
        t('Lingkar pinggang', 280, 20),
        t('100', 160, 60),
        t('86', 280, 60),
        t('L', 40, 100),
        t('104', 160, 100),
      ],
    );
  }
}

void main() {
  Future<MeasurementProvider> setup(
    WidgetTester tester, {
    bool ambiguous = false,
    bool active = true,
  }) async {
    final state = MeasurementProvider(
      DemoMeasurementRepository(
        initialMeasurements: [
          BodyMeasurement(
            id: 'a',
            label: 'Profil A',
            chestCm: 94,
            waistCm: 80,
            measuredAt: DateTime(2026, 11, 10),
          ),
        ],
      ),
    );
    await state.loadMeasurements();
    if (active) state.selectMeasurement('a');
    addTearDown(state.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<MeasurementProvider>.value(
        value: state,
        child: MaterialApp(
          home: MainNavigationScreen(
            screenshotRepository: StructuredRepository(ambiguous: ambiguous),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Analisis'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('pickScreenshot')));
    await tester.tap(find.byKey(const ValueKey('pickScreenshot')));
    await tester.pumpAndSettle();
    return state;
  }

  for (final width in [360.0, 1000.0]) {
    testWidgets('screenshot auto-fills and analyzes without editor at $width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 1000);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final profiles = await setup(tester);
      await reveal(tester, find.text('100'));
      expect(find.text('100'), findsOneWidget);
      expect(find.text('86'), findsOneWidget);
      expect(find.byType(SizeChartReviewScreen), findsNothing);
      final button = find.byKey(const ValueKey('openSizeAnalysis'));
      await reveal(tester, button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      await reveal(
        tester,
        find.byKey(const ValueKey('analysisRecommendation')),
      );
      expect(find.text('Kandidat: M'), findsOneWidget);
      expect(find.byType(SizeChartReviewScreen), findsNothing);
      await profiles.updateMeasurement(
        BodyMeasurement(
          id: 'a',
          label: 'Profil A',
          chestCm: 110,
          waistCm: 90,
          measuredAt: DateTime(2026, 11, 10),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Kandidat: M'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets(
    'ambiguous meaning asks only for correction; numbers remain filled',
    (tester) async {
      await setup(tester, ambiguous: true);
      final button = find.byKey(const ValueKey('openSizeAnalysis'));
      await reveal(tester, button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.byType(SizeChartReviewScreen), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('0_chest')))
            .initialValue,
        '100',
      );
      final type = find.byKey(const ValueKey('chestType'));
      await tester.ensureVisible(type);
      await tester.tap(type);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lingkar penuh').last);
      await tester.pumpAndSettle();
      final save = find.byKey(const ValueKey('saveReviewedChart'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      await reveal(
        tester,
        find.byKey(const ValueKey('analysisRecommendation')),
      );
      expect(find.text('Kandidat: M'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'no active profile blocks calculation but still shows auto-filled table',
    (tester) async {
      await setup(tester, active: false);
      final button = find.byKey(const ValueKey('openSizeAnalysis'));
      await reveal(tester, button);
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      await reveal(tester, find.text('100'), delta: -200);
      expect(find.text('100'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

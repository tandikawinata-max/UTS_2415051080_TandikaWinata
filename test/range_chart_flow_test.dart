import 'package:usize/repositories/demo_analysis_history_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:usize/models/body_measurement.dart';
import 'package:usize/models/ocr_document.dart';
import 'package:usize/models/reviewed_size_chart.dart';
import 'package:usize/models/size_analysis_result.dart';
import 'package:usize/providers/measurement_provider.dart';
import 'package:usize/repositories/demo_measurement_repository.dart';
import 'package:usize/repositories/screenshot_repository.dart';
import 'package:usize/screens/main_navigation_screen.dart';
import 'package:usize/screens/size_chart_review_screen.dart';
import 'scroll_helpers.dart';

class RangeScreenshotRepository
    implements ScreenshotRepository, StructuredScreenshotRepository {
  final String heading;
  RangeScreenshotRepository(this.heading);
  @override
  Future<String?> pickScreenshot() async => '/chart.png';
  @override
  Future<String?> recoverScreenshot() async => null;
  @override
  Future<String> readText(String path) async =>
      throw StateError('Use spatial OCR');
  @override
  Future<OcrDocument> readDocument(String path) async {
    OcrToken t(String text, double x, double y) => OcrToken(
      text: text,
      left: x - 30,
      right: x + 30,
      top: y - 8,
      bottom: y + 8,
    );
    return OcrDocument(
      text:
          '$heading cm\nSIZE DADA PINGGANG\nM 92 - 97 78 - 83\nL 98 - 104 84 - 90',
      tokens: [
        t('SIZE', 40, 20),
        t('DADA', 160, 20),
        t('PINGGANG', 280, 20),
        t('M', 40, 60),
        t('92 - 97', 160, 60),
        t('78 - 83', 280, 60),
        t('L', 40, 100),
        t('98 - 104', 160, 100),
        t('84 - 90', 280, 100),
      ],
    );
  }
}

void main() {
  Future<void> setup(WidgetTester tester, String heading) async {
    final measurements = MeasurementProvider(
      DemoMeasurementRepository(
        initialMeasurements: [
          BodyMeasurement(
            id: 'a',
            label: 'A',
            chestCm: 94,
            waistCm: 80,
            measuredAt: DateTime(2026),
          ),
        ],
      ),
    );
    addTearDown(measurements.dispose);
    await measurements.loadMeasurements();
    measurements.selectMeasurement('a');
    await tester.pumpWidget(
      ChangeNotifierProvider<MeasurementProvider>.value(
        value: measurements,
        child: MaterialApp(
          home: MainNavigationScreen(
            historyRepository: DemoAnalysisHistoryRepository(),
            screenshotRepository: RangeScreenshotRepository(heading),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Analisis'));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const ValueKey('pickScreenshot')));
    await tester.tap(find.byKey(const ValueKey('pickScreenshot')));
    await tester.pumpAndSettle();
  }

  testWidgets('body ranges automatically flow to M with no ease selector', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 1000);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await setup(tester, 'BODY MEASUREMENTS');
    await reveal(tester, find.text('92 - 97'));
    expect(find.text('78 - 83'), findsOneWidget);
    final analyze = find.byKey(const ValueKey('openSizeAnalysis'));
    await reveal(tester, analyze);
    await tester.tap(analyze);
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const ValueKey('analysisRecommendation')));
    expect(find.text('Kandidat: M'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<FitPreference>), findsNothing);
    expect(find.byType(SizeChartReviewScreen), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('unknown basis asks once and keeps original range text', (
    tester,
  ) async {
    await setup(tester, 'SIZE GUIDE');
    final analyze = find.byKey(const ValueKey('openSizeAnalysis'));
    await reveal(tester, analyze);
    await tester.tap(analyze);
    await tester.pumpAndSettle();
    expect(find.byType(SizeChartReviewScreen), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('0_chest')))
          .initialValue,
      '92 - 97',
    );
    final basis = find.byKey(const ValueKey('chartBasis'));
    await reveal(tester, basis);
    await tester.tap(basis);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ukuran tubuh yang cocok').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('chestType')), findsNothing);
    final save = find.byKey(const ValueKey('saveReviewedChart'));
    await reveal(tester, save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const ValueKey('analysisRecommendation')));
    expect(find.text('Kandidat: M'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'editing ranges and changing body to garment needs meaning, preserves both endpoints',
    (tester) async {
      ReviewedSizeChart? result;
      final draft = SizeChartDraft(
        unit: ChartUnit.cm,
        basis: ChartBasis.body,
        rows: const [SizeChartDraftRow(label: 'M', chest: '92 - 97')],
        warnings: [],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () async {
                  result = await Navigator.of(context).push<ReviewedSizeChart>(
                    MaterialPageRoute(
                      builder: (_) => SizeChartReviewScreen(
                        imagePath: '/x.png',
                        ocrText: '',
                        draft: draft,
                      ),
                    ),
                  );
                },
                child: const Text('Buka'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Buka'));
      await tester.pumpAndSettle();
      final field = find.byKey(const ValueKey('0_chest'));
      await reveal(tester, field);
      expect(
        tester
            .widget<TextField>(
              find.descendant(of: field, matching: find.byType(TextField)),
            )
            .keyboardType,
        TextInputType.text,
      );
      await tester.enterText(field, '100 – 104');
      await tester.pumpAndSettle();
      final basis = find.byKey(const ValueKey('chartBasis'));
      await reveal(tester, basis, delta: -200);
      await tester.tap(basis);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ukuran pakaian jadi').last);
      await tester.pumpAndSettle();
      final chestType = find.byKey(const ValueKey('chestType'));
      await reveal(tester, chestType);
      await tester.tap(chestType);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lingkar penuh').last);
      await tester.pumpAndSettle();
      final save = find.byKey(const ValueKey('saveReviewedChart'));
      await reveal(tester, save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(result, isNull);
      final meaning = find.byKey(const ValueKey('rangeMeaning'));
      await reveal(tester, meaning, delta: -200);
      await tester.tap(meaning);
      await tester.pumpAndSettle();
      await tester.tap(find.text(ChartRangeMeaning.variation.label).last);
      await tester.pumpAndSettle();
      await reveal(tester, save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(result?.basis, ChartBasis.garment);
      expect(result?.sizes.single.chestCm.min, 100);
      expect(result?.sizes.single.chestCm.max, 104);
      expect(result?.inputRows.single.chest, '100 – 104');
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

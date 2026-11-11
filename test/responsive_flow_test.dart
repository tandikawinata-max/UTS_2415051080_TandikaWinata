import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:usize/models/analysis_history.dart';
import 'package:usize/models/reviewed_size_chart.dart';
import 'package:usize/providers/measurement_provider.dart';
import 'package:usize/repositories/demo_measurement_repository.dart';
import 'package:usize/screens/main_navigation_screen.dart';
import 'package:usize/screens/size_chart_review_screen.dart';
import 'package:usize/theme/usize_theme.dart';
import 'package:usize/widgets/analysis_result_details.dart';
import 'history_fixtures.dart';
import 'scroll_helpers.dart';

void main() {
  testWidgets('comparison table headings are fully readable at text 200%', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: UsizeTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: AnalysisResultDetails(
                snapshot: AnalysisSnapshot.fromResult(historyResult()),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final labels = find.text('Rentang tubuh tabel\n(cm)');
    expect(labels, findsNWidgets(2));
    for (final element in labels.evaluate()) {
      final paragraph = element.findRenderObject()! as RenderParagraph;
      final painter = TextPainter(
        text: paragraph.text,
        textDirection: paragraph.textDirection,
        textScaler: paragraph.textScaler,
      )..layout(maxWidth: paragraph.size.width);
      expect(painter.height, lessThanOrEqualTo(paragraph.size.height + 0.1));
      painter.dispose();
    }
  });

  for (final width in [320.0, 390.0, 1024.0]) {
    testWidgets('analysis and history remain usable at $width / text 200%', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 700);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final measurements = MeasurementProvider(
        DemoMeasurementRepository(initialMeasurements: [historyProfile()]),
      );
      addTearDown(measurements.dispose);
      await measurements.loadMeasurements();
      measurements.selectMeasurement('profile-a');
      final history = ControlledHistoryRepository();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: measurements,
          child: MaterialApp(
            theme: UsizeTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: MainNavigationScreen(
              historyRepository: history,
              screenshotRepository: HistoryScreenshotRepository(),
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
      await reveal(tester, find.byKey(const ValueKey('openSizeAnalysis')));
      await tester.tap(find.byKey(const ValueKey('openSizeAnalysis')));
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const ValueKey('saveAnalysis')));
      await tester.tap(find.byKey(const ValueKey('saveAnalysis')));
      await tester.pumpAndSettle();
      expect(find.text('Tersimpan'), findsOneWidget);
      await reveal(
        tester,
        find.byKey(const ValueKey('analysisRecommendation')),
      );
      expect(find.text('Kandidat: M'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        0,
      );
      await tester.tap(find.text('Riwayat'));
      await tester.pumpAndSettle();
      expect((await history.fetchPage()).items, hasLength(1));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets(
    'garment range form preserves edits through large text and keyboard',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 700);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetViewInsets);
      final chart = historyResult(garment: true).chart;
      await tester.pumpWidget(
        MaterialApp(
          theme: UsizeTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: SizeChartReviewScreen(
            imagePath: chart.sourceImagePath,
            ocrText: chart.sourceOcrText,
            draft: SizeChartDraft(rows: chart.inputRows, warnings: []),
            initialChart: chart,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final meaning = find.byKey(const ValueKey('rangeMeaning'));
      await reveal(tester, meaning);
      final selectedMeaning = find.descendant(
        of: meaning,
        matching: find.text(ChartRangeMeaning.variation.label),
      );
      final fieldBounds = tester.getRect(meaning);
      final textBounds = tester.getRect(selectedMeaning);
      expect(textBounds.top, greaterThanOrEqualTo(fieldBounds.top));
      expect(textBounds.bottom, lessThanOrEqualTo(fieldBounds.bottom));
      final chest = find.byKey(const ValueKey('0_chest'));
      await reveal(tester, chest);
      await tester.enterText(chest, '100 - 105');
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      await tester.pumpAndSettle();
      await reveal(tester, chest);
      expect(
        tester.widget<TextFormField>(chest).controller?.text ??
            tester.widget<TextFormField>(chest).initialValue,
        '100 - 105',
      );
      tester.view.resetViewInsets();
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const ValueKey('saveReviewedChart')));
      expect(
        find.byKey(const ValueKey('saveReviewedChart')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

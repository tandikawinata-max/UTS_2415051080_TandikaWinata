import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:usize/providers/measurement_provider.dart';
import 'package:usize/repositories/demo_measurement_repository.dart';
import 'package:usize/screens/main_navigation_screen.dart';
import 'package:usize/theme/usize_theme.dart';
import 'history_fixtures.dart';
import 'scroll_helpers.dart';

void main() {
  Future<MeasurementProvider> setup(
    WidgetTester tester,
    ControlledHistoryRepository repo, {
    double chest = 94,
  }) async {
    final measurements = MeasurementProvider(
      DemoMeasurementRepository(
        initialMeasurements: [historyProfile(chest: chest)],
      ),
    );
    addTearDown(measurements.dispose);
    await measurements.loadMeasurements();
    measurements.selectMeasurement('profile-a');
    await tester.pumpWidget(
      ChangeNotifierProvider<MeasurementProvider>.value(
        value: measurements,
        child: MaterialApp(
          theme: UsizeTheme.light,
          home: MainNavigationScreen(
            historyRepository: repo,
            screenshotRepository: HistoryScreenshotRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return measurements;
  }

  for (final width in [360.0, 1000.0]) {
    testWidgets(
      'save, reopen, preserve old profile, cancel/delete history at width $width',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 1000);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final repo = ControlledHistoryRepository();
        final measurements = await setup(tester, repo);
        await tester.tap(find.text('Analisis'));
        await tester.pumpAndSettle();
        await reveal(tester, find.byKey(const ValueKey('pickScreenshot')));
        await tester.tap(find.byKey(const ValueKey('pickScreenshot')));
        await tester.pumpAndSettle();
        await reveal(tester, find.byKey(const ValueKey('openSizeAnalysis')));
        await tester.tap(find.byKey(const ValueKey('openSizeAnalysis')));
        await tester.pumpAndSettle();
        final title = find.byKey(const ValueKey('historyTitle'));
        await reveal(tester, title);
        await tester.enterText(title, 'Kaos linen');
        tester.testTextInput.hide();
        await tester.pumpAndSettle();
        final save = find.byKey(const ValueKey('saveAnalysis'));
        await reveal(tester, save);
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(find.text('Tersimpan'), findsOneWidget);
        expect(repo.saveCalls, 1);
        final savedId = (await repo.fetchPage()).items.single.id;
        await measurements.updateMeasurement(
          historyProfile(chest: 110, label: 'Profil diubah'),
        );
        await tester.pumpAndSettle();
        expect((await repo.findById(savedId))!.snapshot.profile.chestCm, 94);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await setup(tester, repo, chest: 110);
        await tester.tap(find.text('Riwayat'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Kaos linen'));
        await tester.pumpAndSettle();
        await reveal(
          tester,
          find.byKey(const ValueKey('analysisRecommendation')),
        );
        expect(find.text('Kandidat: M'), findsOneWidget);
        expect(find.text('Profil saat dianalisis: Profil A'), findsOneWidget);
        final remove = find.byKey(const ValueKey('deleteHistory'));
        await reveal(tester, remove, delta: -200);
        await tester.tap(remove);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Batal'));
        await tester.pumpAndSettle();
        expect(await repo.findById(savedId), isNotNull);
        await tester.tap(remove);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('confirmDeleteHistory')));
        await tester.pumpAndSettle();
        expect(find.text('Riwayat Analisis'), findsOneWidget);
        expect(find.text('Belum ada analisis tersimpan'), findsOneWidget);
        expect(await repo.findById(savedId), isNull);
        expect(measurements.measurements, hasLength(1));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
  testWidgets(
    'history loading/detail/delete errors expose retry and preserve data',
    (tester) async {
      final repo = ControlledHistoryRepository();
      await repo.save(historyDraft());
      repo.failLoad = true;
      await setup(tester, repo);
      await tester.tap(find.text('Riwayat'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('retryHistory')), findsOneWidget);
      repo.failLoad = false;
      await tester.tap(find.byKey(const ValueKey('retryHistory')));
      await tester.pumpAndSettle();
      repo.failDetail = true;
      await tester.tap(find.text('Kemeja linen'));
      await tester.pumpAndSettle();
      expect(find.text('Coba lagi'), findsOneWidget);
      repo.failDetail = false;
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();
      repo.failDelete = true;
      await reveal(tester, find.byKey(const ValueKey('deleteHistory')));
      await tester.tap(find.byKey(const ValueKey('deleteHistory')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirmDeleteHistory')));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Penghapusan belum terkonfirmasi. Coba hapus lagi atau muat ulang riwayat.',
        ),
        findsOneWidget,
      );
      expect(await repo.findById(historyResultId), isNotNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

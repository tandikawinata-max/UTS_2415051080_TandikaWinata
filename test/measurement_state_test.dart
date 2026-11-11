import 'package:flutter_test/flutter_test.dart';
import 'package:usize/main.dart';
import 'package:usize/models/body_measurement.dart';
import 'package:usize/providers/measurement_provider.dart';
import 'package:usize/repositories/demo_measurement_repository.dart';

import 'scroll_helpers.dart';

class FailingOnceRepository extends DemoMeasurementRepository {
  bool _shouldFail = true;

  @override
  Future<List<BodyMeasurement>> getMeasurements() async {
    if (_shouldFail) {
      _shouldFail = false;
      throw Exception('Simulasi gagal memuat data.');
    }

    return super.getMeasurements();
  }
}

void main() {
  test('Provider memuat data dan mempertahankan profil aktif', () async {
    final repository = DemoMeasurementRepository();
    final state = MeasurementProvider(repository);

    addTearDown(state.dispose);

    final loading = state.loadMeasurements();

    expect(state.isLoading, isTrue);

    await loading;

    expect(state.isLoading, isFalse);
    expect(state.measurements, hasLength(3));
    expect(state.errorMessage, isNull);

    state.selectMeasurement('demo-02');

    expect(state.activeMeasurement?.label, 'Profil Contoh B');

    await state.loadMeasurements();

    expect(state.activeMeasurementId, 'demo-02');

    await repository.deleteMeasurement('demo-02');
    await state.loadMeasurements();

    expect(state.activeMeasurement, isNull);
    expect(state.activeMeasurementId, isNull);
  });

  test('Data kosong menghasilkan daftar kosong', () async {
    final repository = DemoMeasurementRepository(initialMeasurements: []);
    final state = MeasurementProvider(repository);

    addTearDown(state.dispose);

    await state.loadMeasurements();

    expect(state.measurements, isEmpty);
    expect(state.activeMeasurement, isNull);
    expect(state.errorMessage, isNull);
  });

  testWidgets('Tombol coba lagi memulihkan pemuatan profil', (tester) async {
    await tester.pumpWidget(MyApp(repository: FailingOnceRepository()));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Profil belum dapat dimuat. Periksa koneksi internet, lalu coba lagi.',
      ),
      findsOneWidget,
    );

    final retryButton = find.text('Coba lagi');

    await tester.ensureVisible(retryButton);
    await tester.tap(retryButton);
    await tester.pumpAndSettle();

    expect(find.text('Coba lagi'), findsNothing);
    expect(find.text('Belum ada profil aktif'), findsOneWidget);
  });

  testWidgets('Profil aktif digunakan bersama oleh Beranda dan Analisis', (
    tester,
  ) async {
    await tester.pumpWidget(MyApp(repository: DemoMeasurementRepository()));
    await tester.pumpAndSettle();

    final listButton = find.text('Lihat semua profil');

    await reveal(tester, listButton);
    await tester.tap(listButton);
    await tester.pumpAndSettle();

    final selectedProfile = find.text('Profil Contoh B');

    await tester.ensureVisible(selectedProfile);
    await tester.tap(selectedProfile);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Gunakan profil ini'));
    await tester.pumpAndSettle();

    expect(find.text('Profil ini aktif'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();

    final activeProfile = find.text('Profil aktif: Profil Contoh B');

    await reveal(tester, activeProfile, delta: -200);

    expect(activeProfile, findsOneWidget);

    await tester.tap(find.text('Analisis'));
    await tester.pumpAndSettle();

    expect(find.text('Profil aktif: Profil Contoh B'), findsOneWidget);
  });
}

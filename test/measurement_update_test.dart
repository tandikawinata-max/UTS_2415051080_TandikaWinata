import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:usize/models/body_measurement.dart';
import 'package:usize/providers/measurement_provider.dart';
import 'package:usize/repositories/demo_measurement_repository.dart';
import 'package:usize/screens/measurement_detail_screen.dart';

final original = BodyMeasurement(
  id: 'profile-a',
  userId: 'user-a',
  label: 'Profil Awal',
  chestCm: 94,
  waistCm: 80,
  measuredAt: DateTime(2026, 11, 9),
);

class EditRepository extends DemoMeasurementRepository {
  EditRepository() : super(initialMeasurements: [original]);

  int updateCalls = 0;
  int createCalls = 0;
  bool failNextUpdate = false;

  @override
  Future<BodyMeasurement> createMeasurement(BodyMeasurement measurement) async {
    createCalls++;
    return super.createMeasurement(measurement);
  }

  @override
  Future<BodyMeasurement> updateMeasurement(BodyMeasurement measurement) async {
    updateCalls++;

    if (failNextUpdate) {
      failNextUpdate = false;
      throw StateError('Simulasi gagal memperbarui.');
    }

    return super.updateMeasurement(measurement);
  }
}

Widget testApp(EditRepository repository) {
  return ChangeNotifierProvider(
    create: (_) => MeasurementProvider(repository)..loadMeasurements(),
    child: MaterialApp(
      home: MeasurementDetailScreen(measurementId: original.id),
    ),
  );
}

Future<void> openEdit(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Edit profil'));
  await tester.pumpAndSettle();
}

Future<void> saveForm(WidgetTester tester) async {
  final button = find.byKey(const ValueKey('saveMeasurement'));

  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  test('payload UPDATE mengecualikan identitas dan membawa null', () {
    final data = original.toUpdateJson();

    expect(data.containsKey('id'), isFalse);
    expect(data.containsKey('user_id'), isFalse);
    expect(data.containsKey('created_at'), isFalse);
    expect(data.containsKey('hip_cm'), isTrue);
    expect(data['hip_cm'], isNull);
  });

  test('edit memperbarui profil aktif tanpa menambah jumlah profil', () async {
    final repository = EditRepository();
    final provider = MeasurementProvider(repository);
    addTearDown(provider.dispose);

    await provider.loadMeasurements();
    provider.selectMeasurement(original.id);

    final edited = BodyMeasurement(
      id: original.id,
      userId: original.userId,
      label: 'Profil Diperbarui',
      chestCm: 98.5,
      waistCm: null,
      measuredAt: original.measuredAt,
    );

    final saved = await provider.updateMeasurement(edited);

    expect(saved, isNotNull);
    expect(provider.measurements.length, 1);
    expect(provider.activeMeasurementId, original.id);
    expect(provider.activeMeasurement!.chestCm, 98.5);
    expect(provider.activeMeasurement!.waistCm, isNull);
    expect(repository.createCalls, 0);

    await provider.loadMeasurements();

    expect(provider.activeMeasurement!.label, 'Profil Diperbarui');
  });

  testWidgets('form terisi dan perubahan tampil pada detail', (tester) async {
    final repository = EditRepository();

    await tester.pumpWidget(testApp(repository));
    await tester.pumpAndSettle();
    await openEdit(tester);

    final nameField = tester.widget<TextFormField>(
      find.byKey(const ValueKey('label')),
    );
    final waistField = tester.widget<TextFormField>(
      find.byKey(const ValueKey('waist')),
    );

    expect(nameField.controller!.text, 'Profil Awal');
    expect(waistField.controller!.text, '80');

    await tester.enterText(
      find.byKey(const ValueKey('label')),
      'Profil Diperbarui',
    );
    await tester.enterText(find.byKey(const ValueKey('chest')), '98,5');
    await tester.enterText(find.byKey(const ValueKey('waist')), '');

    await saveForm(tester);

    expect(find.text('Profil Diperbarui'), findsOneWidget);
    expect(find.text('98.5 cm'), findsOneWidget);
    expect(repository.updateCalls, 1);
    expect(repository.createCalls, 0);

    final stored = await repository.getMeasurements();

    expect(stored.length, 1);
    expect(stored.single.id, original.id);
    expect(stored.single.waistCm, isNull);
  });

  testWidgets('gagal edit mempertahankan isian dan bisa dicoba lagi', (
    tester,
  ) async {
    final repository = EditRepository()..failNextUpdate = true;

    await tester.pumpWidget(testApp(repository));
    await tester.pumpAndSettle();
    await openEdit(tester);

    await tester.enterText(find.byKey(const ValueKey('chest')), '99');

    await saveForm(tester);

    expect(
      find.textContaining('Perubahan belum dapat dikonfirmasi'),
      findsOneWidget,
    );

    final chestField = tester.widget<TextFormField>(
      find.byKey(const ValueKey('chest')),
    );

    expect(chestField.controller!.text, '99');
    expect((await repository.getMeasurements()).single.chestCm, 94);

    await saveForm(tester);

    expect(find.text('99 cm'), findsOneWidget);
    expect(repository.updateCalls, 2);
    expect(repository.createCalls, 0);
  });

  testWidgets('kembali tanpa menyimpan mempertahankan data lama', (
    tester,
  ) async {
    final repository = EditRepository();

    await tester.pumpWidget(testApp(repository));
    await tester.pumpAndSettle();
    await openEdit(tester);

    await tester.enterText(
      find.byKey(const ValueKey('label')),
      'Draf yang dibatalkan',
    );

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Profil Awal'), findsOneWidget);
    expect(repository.updateCalls, 0);
    expect(repository.createCalls, 0);
  });
}

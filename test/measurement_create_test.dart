import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:usize/models/body_measurement.dart';
import 'package:usize/providers/measurement_provider.dart';
import 'package:usize/repositories/demo_measurement_repository.dart';
import 'package:usize/screens/measurement_list_screen.dart';
import 'package:usize/utils/measurement_validators.dart';

class RecordingRepository extends DemoMeasurementRepository {
  RecordingRepository() : super(initialMeasurements: const []);

  final attempts = <BodyMeasurement>[];
  bool failNextSave = false;
  Completer<BodyMeasurement>? pendingSave;

  @override
  Future<BodyMeasurement> createMeasurement(BodyMeasurement measurement) async {
    attempts.add(measurement);

    if (pendingSave != null) {
      return pendingSave!.future;
    }

    if (failNextSave) {
      failNextSave = false;
      throw StateError('Simulasi koneksi gagal.');
    }

    return super.createMeasurement(measurement);
  }
}

Widget testApp(RecordingRepository repository) {
  return ChangeNotifierProvider(
    create: (_) => MeasurementProvider(repository)..loadMeasurements(),
    child: const MaterialApp(home: MeasurementListScreen()),
  );
}

Future<void> openForm(WidgetTester tester) async {
  await tester.tap(find.text('Tambah profil'));
  await tester.pumpAndSettle();
}

Future<void> tapSave(WidgetTester tester) async {
  final button = find.byKey(const ValueKey('saveMeasurement'));

  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  test('validator menerima desimal dan menolak nilai tidak valid', () {
    expect(MeasurementValidators.number('94,5'), isNull);
    expect(MeasurementValidators.number('94.5'), isNull);
    expect(MeasurementValidators.parseOptional('94,5'), 94.5);
    expect(MeasurementValidators.number(''), isNull);

    expect(MeasurementValidators.number('', isRequired: true), isNotNull);

    for (final value in [
      '0',
      '-1',
      'abc',
      'NaN',
      'Infinity',
      '1,2.3',
      '12.345',
      '10000',
    ]) {
      expect(
        MeasurementValidators.number(value),
        isNotNull,
        reason: 'Nilai $value harus ditolak.',
      );
    }
  });

  testWidgets('form kosong tidak mengirim permintaan simpan', (tester) async {
    final repository = RecordingRepository();

    await tester.pumpWidget(testApp(repository));
    await tester.pumpAndSettle();
    await openForm(tester);
    await tapSave(tester);

    expect(find.text('Nama profil wajib diisi.'), findsOneWidget);
    expect(find.text('Ukuran ini wajib diisi.'), findsOneWidget);
    expect(repository.attempts, isEmpty);
  });

  testWidgets('isian dan ID tetap tersedia setelah simpan gagal', (
    tester,
  ) async {
    final repository = RecordingRepository()..failNextSave = true;

    await tester.pumpWidget(testApp(repository));
    await tester.pumpAndSettle();
    await openForm(tester);

    await tester.enterText(find.byKey(const ValueKey('label')), 'Profil Baru');
    await tester.enterText(find.byKey(const ValueKey('chest')), '94,5');

    await tapSave(tester);

    expect(repository.attempts.length, 1);
    expect(
      find.textContaining('Penyimpanan belum dapat dikonfirmasi'),
      findsOneWidget,
    );

    final nameField = tester.widget<TextFormField>(
      find.byKey(const ValueKey('label')),
    );

    expect(nameField.controller!.text, 'Profil Baru');

    await tapSave(tester);

    expect(repository.attempts.length, 2);
    expect(repository.attempts[0].id, repository.attempts[1].id);
    expect(repository.attempts[1].chestCm, 94.5);
    expect(find.text('Profil Baru'), findsOneWidget);
    expect(find.byKey(const ValueKey('saveMeasurement')), findsNothing);
  });

  test('provider mencegah dua penyimpanan bersamaan', () async {
    final repository = RecordingRepository();
    final pending = Completer<BodyMeasurement>();
    repository.pendingSave = pending;

    final provider = MeasurementProvider(repository);
    addTearDown(provider.dispose);

    final draft = BodyMeasurement(
      id: 'test-profile',
      label: 'Profil Tes',
      chestCm: 94,
      measuredAt: DateTime(2026, 11, 9),
    );

    final firstSave = provider.createMeasurement(draft);
    final secondSave = await provider.createMeasurement(draft);

    expect(provider.isSaving, isTrue);
    expect(secondSave, isNull);
    expect(repository.attempts.length, 1);

    pending.complete(draft);

    expect(await firstSave, same(draft));
    expect(provider.isSaving, isFalse);
    expect(provider.measurements.length, 1);
  });
}

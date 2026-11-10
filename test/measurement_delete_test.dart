import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:usize/models/body_measurement.dart';
import 'package:usize/providers/measurement_provider.dart';
import 'package:usize/repositories/demo_measurement_repository.dart';
import 'package:usize/screens/measurement_detail_screen.dart';
import 'package:usize/screens/measurement_list_screen.dart';

final profileA = BodyMeasurement(
  id: 'profile-a',
  label: 'Profil A',
  chestCm: 94,
  measuredAt: DateTime(2026, 11, 10),
);

final profileB = BodyMeasurement(
  id: 'profile-b',
  label: 'Profil B',
  chestCm: 100,
  measuredAt: DateTime(2026, 11, 10),
);

class DeleteRepository extends DemoMeasurementRepository {
  DeleteRepository({List<BodyMeasurement>? items})
    : super(initialMeasurements: items ?? [profileA, profileB]);

  int deleteCalls = 0;
  bool failNextDelete = false;
  Completer<void>? pendingDelete;

  @override
  Future<void> deleteMeasurement(String id) async {
    deleteCalls++;

    if (pendingDelete != null) {
      await pendingDelete!.future;
    }

    if (failNextDelete) {
      failNextDelete = false;
      throw StateError('Simulasi gagal hapus.');
    }

    await super.deleteMeasurement(id);
  }
}

Widget testApp(DeleteRepository repository) {
  return ChangeNotifierProvider(
    create: (_) => MeasurementProvider(repository)..loadMeasurements(),
    child: const MaterialApp(home: MeasurementListScreen()),
  );
}

Future<void> openProfileA(WidgetTester tester) async {
  final profile = find.text('Profil A');

  await tester.ensureVisible(profile);
  await tester.tap(profile);
  await tester.pumpAndSettle();
}

Future<void> openDeleteDialog(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('deleteMeasurement')));
  await tester.pumpAndSettle();
}

void main() {
  for (final deleteActive in [true, false]) {
    test(
      deleteActive
          ? 'hapus profil aktif mengosongkan pilihan aktif'
          : 'hapus profil lain mempertahankan pilihan aktif',
      () async {
        final repository = DeleteRepository();
        final provider = MeasurementProvider(repository);
        addTearDown(provider.dispose);

        await provider.loadMeasurements();
        provider.selectMeasurement(profileA.id);

        final targetId = deleteActive ? profileA.id : profileB.id;
        final success = await provider.deleteMeasurement(targetId);

        expect(success, isTrue);
        expect(provider.findById(targetId), isNull);
        expect(provider.measurements.length, 1);
        expect(
          provider.activeMeasurementId,
          deleteActive ? isNull : profileA.id,
        );

        await provider.loadMeasurements();

        expect(provider.findById(targetId), isNull);
      },
    );
  }

  test('gagal hapus mempertahankan data dan dapat dicoba lagi', () async {
    final repository = DeleteRepository()..failNextDelete = true;
    final provider = MeasurementProvider(repository);
    addTearDown(provider.dispose);

    await provider.loadMeasurements();
    provider.selectMeasurement(profileA.id);

    expect(await provider.deleteMeasurement(profileA.id), isFalse);
    expect(provider.findById(profileA.id), isNotNull);
    expect(provider.activeMeasurementId, profileA.id);
    expect(provider.deleteErrorFor(profileA.id), isNotNull);
    expect(provider.isDeleting, isFalse);

    expect(await provider.deleteMeasurement(profileA.id), isTrue);
    expect(provider.findById(profileA.id), isNull);
    expect(provider.activeMeasurementId, isNull);
    expect(provider.deleteErrorMessage, isNull);
  });

  test('provider mencegah dua penghapusan bersamaan', () async {
    final pending = Completer<void>();
    final repository = DeleteRepository()..pendingDelete = pending;
    final provider = MeasurementProvider(repository);
    addTearDown(provider.dispose);

    await provider.loadMeasurements();

    final firstDelete = provider.deleteMeasurement(profileA.id);
    final secondDelete = await provider.deleteMeasurement(profileA.id);

    expect(provider.isDeleting, isTrue);
    expect(secondDelete, isFalse);
    expect(repository.deleteCalls, 1);

    pending.complete();

    expect(await firstDelete, isTrue);
    expect(provider.isDeleting, isFalse);
  });

  testWidgets('Batal pada dialog tidak menghapus profil', (tester) async {
    final repository = DeleteRepository();

    await tester.pumpWidget(testApp(repository));
    await tester.pumpAndSettle();
    await openProfileA(tester);
    await openDeleteDialog(tester);

    expect(find.text('Hapus profil?'), findsOneWidget);

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(repository.deleteCalls, 0);
    expect(find.byType(MeasurementDetailScreen), findsOneWidget);
    expect(find.text('Profil A'), findsOneWidget);
  });

  testWidgets('hapus profil terakhir kembali ke daftar kosong', (tester) async {
    final repository = DeleteRepository(items: [profileA]);

    await tester.pumpWidget(testApp(repository));
    await tester.pumpAndSettle();
    await openProfileA(tester);

    await tester.tap(find.text('Gunakan profil ini'));
    await tester.pumpAndSettle();

    await openDeleteDialog(tester);
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();

    expect(repository.deleteCalls, 1);
    expect(find.byType(MeasurementDetailScreen), findsNothing);
    expect(find.text('Belum ada profil'), findsOneWidget);
    expect(find.text('Profil "Profil A" berhasil dihapus.'), findsOneWidget);

    final provider = tester
        .element(find.byType(MeasurementListScreen))
        .read<MeasurementProvider>();

    expect(provider.activeMeasurementId, isNull);
    expect(provider.measurements, isEmpty);
  });

  testWidgets('gagal hapus menampilkan pesan dan tombol coba lagi', (
    tester,
  ) async {
    final repository = DeleteRepository(items: [profileA])
      ..failNextDelete = true;

    await tester.pumpWidget(testApp(repository));
    await tester.pumpAndSettle();
    await openProfileA(tester);
    await openDeleteDialog(tester);

    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();

    expect(find.byType(MeasurementDetailScreen), findsOneWidget);
    expect(
      find.textContaining('Penghapusan belum dapat dikonfirmasi'),
      findsOneWidget,
    );
    expect(find.text('Coba lagi'), findsOneWidget);

    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();

    expect(repository.deleteCalls, 2);
    expect(find.text('Belum ada profil'), findsOneWidget);
  });
}

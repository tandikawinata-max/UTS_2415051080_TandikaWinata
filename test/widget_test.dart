import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usize/main.dart';
import 'package:usize/widgets/measurement_card.dart';

void main() {
  for (final width in [400.0, 1000.0]) {
    testWidgets('Susunan profil menyesuaikan lebar $width', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 1000);

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MyApp());

      expect(find.text('Kenali ukuranmu'), findsOneWidget);

      final cards = find.byType(MeasurementCard);

      await tester.ensureVisible(cards.first);
      await tester.pumpAndSettle();

      expect(cards, findsNWidgets(3));

      final firstPosition = tester.getTopLeft(cards.at(0));
      final secondPosition = tester.getTopLeft(cards.at(1));

      if (width < 600) {
        expect(secondPosition.dx, firstPosition.dx);
        expect(secondPosition.dy, greaterThan(firstPosition.dy));
      } else {
        expect(secondPosition.dy, firstPosition.dy);
        expect(secondPosition.dx, greaterThan(firstPosition.dx));
      }

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Menu utama berpindah dan Back menuju Beranda', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Analisis'));
    await tester.pumpAndSettle();

    expect(find.text('Usize — Uji OCR'), findsOneWidget);

    await tester.tap(find.text('Riwayat'));
    await tester.pumpAndSettle();

    expect(find.text('Riwayat Analisis'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    final navigationBar = tester.widget<NavigationBar>(
      find.byType(NavigationBar),
    );

    expect(navigationBar.selectedIndex, 0);
    expect(find.text('Kenali ukuranmu'), findsOneWidget);
  });

  testWidgets('Tombol dashboard mengaktifkan menu Analisis', (tester) async {
    await tester.pumpWidget(const MyApp());

    final button = find.text('Buka pembaca tabel');

    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    final navigationBar = tester.widget<NavigationBar>(
      find.byType(NavigationBar),
    );

    expect(navigationBar.selectedIndex, 1);
    expect(find.text('Pilih screenshot'), findsOneWidget);
  });

  testWidgets('Detail menampilkan profil yang dipilih dari daftar', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    final listButton = find.text('Lihat semua profil');

    await tester.ensureVisible(listButton);
    await tester.tap(listButton);
    await tester.pumpAndSettle();

    expect(find.text('Daftar Profil'), findsOneWidget);

    final selectedProfile = find.text('Profil Contoh B');

    await tester.ensureVisible(selectedProfile);
    await tester.tap(selectedProfile);
    await tester.pumpAndSettle();

    expect(find.text('Detail Profil'), findsOneWidget);
    expect(find.text('Profil Contoh B'), findsOneWidget);
    expect(find.text('100.0 cm'), findsOneWidget);
    expect(find.text('Profil Contoh A'), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Daftar Profil'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Kenali ukuranmu'), findsOneWidget);
  });
}

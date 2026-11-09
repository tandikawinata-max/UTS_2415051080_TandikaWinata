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

  testWidgets('Dashboard dapat membuka halaman OCR', (tester) async {
    await tester.pumpWidget(const MyApp());

    final button = find.text('Buka pembaca tabel');

    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('Usize — Uji OCR'), findsOneWidget);
    expect(find.text('Pilih screenshot'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Kenali ukuranmu'), findsOneWidget);
  });
}

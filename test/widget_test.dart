import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usize/main.dart';

void main() {
  testWidgets('Halaman uji OCR menampilkan kondisi awal', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Usize — Uji OCR'), findsOneWidget);
    expect(find.text('Pilih screenshot'), findsOneWidget);
    expect(find.text('Belum ada teks yang ditampilkan.'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });
}

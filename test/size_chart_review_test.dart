import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usize/models/reviewed_size_chart.dart';
import 'package:usize/providers/screenshot_provider.dart';
import 'package:usize/repositories/screenshot_repository.dart';
import 'package:usize/screens/size_chart_review_screen.dart';
import 'package:usize/services/size_chart_parser.dart';

const sourceText = 'SIZE DADA BAHU\nM 50 40';

class ReviewTestRepository implements ScreenshotRepository {
  String? pickedPath = '/chart.png';

  @override
  Future<String?> pickScreenshot() async => pickedPath;

  @override
  Future<String?> recoverScreenshot() async => null;

  @override
  Future<String> readText(String imagePath) async => sourceText;
}

ReviewedSizeChart makeChart() {
  return ReviewedSizeChart.confirm(
    sourceImagePath: '/chart.png',
    sourceOcrText: sourceText,
    unit: ChartUnit.cm,
    chestType: ChartMeasureType.flatWidth,
    rows: const [SizeChartDraftRow(label: 'M', chest: '50', shoulder: '40')],
  );
}

void main() {
  const parser = SizeChartParser();

  test('membaca ukuran pada baris dan mempertahankan posisi kolom', () {
    final draft = parser.parse(
      'SIZE DADA PANJANG BAJU BAHU\n'
      'S 92 68 38\n'
      'M 96 70 40',
    );

    expect(draft.rows.length, 2);
    expect(draft.rows[0].chest, '92');
    expect(draft.rows[1].label, 'M');
    expect(draft.rows[1].shoulder, '40');
  });

  test('membaca ukuran pada kolom meskipun OCR terpisah per baris', () {
    final draft = parser.parse(
      'UKURAN\nS\nM\nL\n'
      'DADA\n92\n96\n100\n'
      'BAHU\n38\n40\n42',
    );

    expect(draft.rows.length, 3);
    expect(draft.rows[1].label, 'M');
    expect(draft.rows[1].chest, '96');
    expect(draft.rows[2].shoulder, '42');
  });

  test('jumlah angka yang tidak cocok tidak digeser atau ditebak', () {
    final draft = parser.parse('S M L\nDADA 92 96\nBAHU 38 40 42');

    expect(draft.rows.every((row) => row.chest.isEmpty), isTrue);
    expect(draft.rows[2].shoulder, '42');
    expect(draft.warnings, isNotEmpty);
  });

  test('rentang angka tidak dianggap sebagai satu angka', () {
    final draft = parser.parse('SIZE DADA BAHU\nM 90-96 40');

    expect(draft.rows.single.chest, isEmpty);
    expect(draft.warnings, isNotEmpty);
    expect(SizeChartRules.number('90-96'), isNotNull);
    expect(SizeChartRules.number('94,5'), isNull);
    expect(SizeChartRules.number('0'), isNotNull);
  });

  test('konversi inci dan bentang benar, bahu tidak dikalikan dua', () {
    final chart = ReviewedSizeChart.confirm(
      sourceImagePath: '/inch.png',
      sourceOcrText: '',
      unit: ChartUnit.inch,
      chestType: ChartMeasureType.flatWidth,
      waistType: ChartMeasureType.circumference,
      hipType: ChartMeasureType.flatWidth,
      rows: const [
        SizeChartDraftRow(
          label: 'M',
          chest: '20',
          waist: '30',
          hip: '21',
          shoulder: '16',
        ),
      ],
    );

    final row = chart.sizes.single;

    expect(row.chestCm, closeTo(101.6, 0.0001));
    expect(row.waistCm, closeTo(76.2, 0.0001));
    expect(row.hipCm, closeTo(106.68, 0.0001));
    expect(row.shoulderWidthCm, closeTo(40.64, 0.0001));
    expect(chart.inputRows.single.chest, '20');
  });

  test('nama ukuran duplikat ditolak tanpa membedakan kapital', () {
    expect(
      () => ReviewedSizeChart.confirm(
        sourceImagePath: '/chart.png',
        sourceOcrText: '',
        unit: ChartUnit.cm,
        chestType: ChartMeasureType.circumference,
        rows: const [
          SizeChartDraftRow(label: 'M', chest: '96'),
          SizeChartDraftRow(label: ' m ', chest: '100'),
        ],
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('pinggang yang diisi memerlukan jenis pengukuran', () {
    expect(
      () => ReviewedSizeChart.confirm(
        sourceImagePath: '/chart.png',
        sourceOcrText: '',
        unit: ChartUnit.cm,
        chestType: ChartMeasureType.circumference,
        rows: const [SizeChartDraftRow(label: 'M', chest: '96', waist: '80')],
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('membatalkan galeri mempertahankan tabel terverifikasi', () async {
    final repository = ReviewTestRepository();
    final state = ScreenshotProvider(repository);
    addTearDown(state.dispose);

    await state.pickScreenshot();

    final chart = makeChart();

    expect(state.confirmChart(chart, expectedRevision: state.revision), isTrue);

    repository.pickedPath = null;
    await state.pickScreenshot();

    expect(state.reviewedChart, same(chart));
  });

  test(
    'membaca ulang membatalkan verifikasi dan menolak revisi lama',
    () async {
      final state = ScreenshotProvider(ReviewTestRepository());
      addTearDown(state.dispose);

      await state.pickScreenshot();

      final revision = state.revision;
      final chart = makeChart();

      state.confirmChart(chart, expectedRevision: revision);
      await state.readAgain();

      expect(state.reviewedChart, isNull);
      expect(state.confirmChart(chart, expectedRevision: revision), isFalse);
    },
  );

  test('gambar baru dan pengosongan membatalkan tabel lama', () async {
    final repository = ReviewTestRepository();
    final state = ScreenshotProvider(repository);
    addTearDown(state.dispose);

    await state.pickScreenshot();
    final chart = makeChart();

    state.confirmChart(chart, expectedRevision: state.revision);

    repository.pickedPath = '/different.png';
    await state.pickScreenshot();

    expect(state.reviewedChart, isNull);
    expect(
      state.confirmChart(chart, expectedRevision: state.revision),
      isFalse,
    );

    state.clearScreenshot();

    expect(state.imagePath, isNull);
    expect(state.reviewedChart, isNull);
  });

  testWidgets('form memerlukan konfirmasi sebelum mengembalikan tabel', (
    tester,
  ) async {
    ReviewedSizeChart? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: FilledButton(
                onPressed: () async {
                  result = await Navigator.of(context).push<ReviewedSizeChart>(
                    MaterialPageRoute<ReviewedSizeChart>(
                      builder: (_) => SizeChartReviewScreen(
                        imagePath: '/chart.png',
                        ocrText: sourceText,
                        draft: parser.parse(sourceText),
                      ),
                    ),
                  );
                },
                child: const Text('Buka pemeriksaan'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Buka pemeriksaan'));
    await tester.pumpAndSettle();

    final unitField = find.byKey(const ValueKey('chartUnit'));
    await tester.ensureVisible(unitField);
    await tester.tap(unitField);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sentimeter (cm)').last);
    await tester.pumpAndSettle();

    final typeField = find.byKey(const ValueKey('chestType'));
    await tester.ensureVisible(typeField);
    await tester.tap(typeField);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lebar bentang (×2)').last);
    await tester.pumpAndSettle();

    final saveButton = find.byKey(const ValueKey('saveReviewedChart'));
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(result, isNull);
    expect(
      find.text('Centang konfirmasi setelah memeriksa tabel.'),
      findsOneWidget,
    );

    final checkbox = find.byKey(const ValueKey('confirmChartCheckbox'));

    await tester.ensureVisible(checkbox);
    await tester.tap(checkbox);
    await tester.pumpAndSettle();

    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.sizes.single.chestCm, 100);
    expect(result!.sizes.single.shoulderWidthCm, 40);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:usize/models/measurement_range.dart';
import 'package:usize/models/reviewed_size_chart.dart';
import 'package:usize/services/size_chart_parser.dart';
import 'package:usize/models/ocr_document.dart';

void main() {
  for (final source in [
    '92-97',
    '92 -97',
    '92- 97',
    '92 - 97',
    '92–97',
    '92 — 97',
    ' 92 − 97 ',
    '92‑97',
  ]) {
    test('range accepted without losing endpoints: $source', () {
      expect(SizeChartRules.number(source), isNull);
      final range = SizeChartRules.parseOptional(source)!;
      expect(range.min, 92);
      expect(range.max, 97);
      expect(range.isRange, isTrue);
    });
  }
  test('single values, decimals and optional dashes', () {
    final single = SizeChartRules.parseOptional('94')!;
    expect(single.min, 94);
    expect(single.max, 94);
    expect(single.isRange, isFalse);
    final decimal = SizeChartRules.parseOptional('92,5 - 97.75')!;
    expect(decimal.min, 92.5);
    expect(decimal.max, 97.75);
    expect(SizeChartRules.parseOptional('—'), isNull);
    expect(SizeChartRules.parseOptional(' '), isNull);
    expect(SizeChartRules.number('-', requiredValue: true), isNotNull);
  });
  test('invalid ranges are not reordered or silently repaired', () {
    for (final invalid in [
      '97-92',
      '-92',
      '0-97',
      '9 4',
      '92--97',
      '92-',
      '-97',
      '92/97',
      '92-97-100',
      '92.123-97',
      'NaN',
      'Infinity',
      '1-10000',
    ]) {
      expect(SizeChartRules.number(invalid), isNotNull, reason: invalid);
      expect(
        () => SizeChartRules.parseOptional(invalid),
        throwsFormatException,
        reason: invalid,
      );
    }
  });
  test('format preserves zeros, signs and range endpoints', () {
    expect(const MeasurementRange.single(100).format(), '100');
    expect(const MeasurementRange.single(10.5).format(), '10.5');
    expect(
      const MeasurementRange.interval(-2, 3).format(signed: true),
      '-2 – +3',
    );
  });
  test('both endpoints converted; shoulder not doubled; source retained', () {
    final chart = ReviewedSizeChart.confirm(
      sourceImagePath: '/x.png',
      sourceOcrText: '',
      unit: ChartUnit.inch,
      basis: ChartBasis.garment,
      rangeMeaning: ChartRangeMeaning.variation,
      chestType: ChartMeasureType.flatWidth,
      rows: const [
        SizeChartDraftRow(label: 'M', chest: '20 - 21', shoulder: '16–17'),
      ],
    );
    final row = chart.sizes.single;
    expect(row.chestCm.min, closeTo(101.6, 1e-8));
    expect(row.chestCm.max, closeTo(106.68, 1e-8));
    expect(row.shoulderWidthCm!.min, closeTo(40.64, 1e-8));
    expect(row.shoulderWidthCm!.max, closeTo(43.18, 1e-8));
    expect(chart.inputRows.single.chest, '20 - 21');
  });
  test('body chart cannot apply flat-width conversion', () {
    expect(
      () => ReviewedSizeChart.confirm(
        sourceImagePath: '/x.png',
        sourceOcrText: '',
        unit: ChartUnit.cm,
        basis: ChartBasis.body,
        chestType: ChartMeasureType.flatWidth,
        rows: const [SizeChartDraftRow(label: 'M', chest: '92-97')],
      ),
      throwsFormatException,
    );
  });
  test(
    'text-only parser groups ranges before splitting cells, both orientations',
    () {
      const parser = SizeChartParser();
      final rows = parser.parse(
        'BODY MEASUREMENTS cm\nSIZE DADA PINGGANG\nM 92 - 97 78–83\nL 98-104 84 - 90',
      );
      expect(rows.rows.first.chest, '92-97');
      expect(rows.rows.first.waist, '78-83');
      expect(rows.rows.last.chest, '98-104');
      expect(rows.rows.last.waist, '84-90');
      expect(rows.basis, ChartBasis.body);
      expect(
        rows.confirm(imagePath: '/x.png', ocrText: '').sizes.first.chestCm.max,
        97,
      );
      final columns = parser.parse(
        'BODY MEASUREMENTS cm\nSIZE M L\nDADA 92 - 97 98–104\nPINGGANG 78 - 83 84-90',
      );
      expect(columns.rows.last.waist, '84-90');
    },
  );
  test(
    'spatial parser assembles split endpoints and keeps empty neighbouring cells',
    () {
      OcrToken t(String value, double x, double y) => OcrToken(
        text: value,
        left: x - 9,
        right: x + 9,
        top: y - 8,
        bottom: y + 8,
      );
      final draft = const SizeChartParser().parseDocument(
        OcrDocument(
          text: 'BODY MEASUREMENTS cm',
          tokens: [
            t('SIZE', 40, 20),
            t('DADA', 160, 20),
            t('PINGGANG', 280, 20),
            t('BAHU', 400, 20),
            t('M', 40, 60),
            t('92', 140, 60),
            t('-', 160, 60),
            t('97', 180, 60),
            t('40', 400, 60),
          ],
        ),
      );
      expect(draft.rows.single.chest, '92 - 97');
      expect(draft.rows.single.waist, isEmpty);
      expect(draft.rows.single.shoulder, '40');
      expect(draft.basis, ChartBasis.body);
      expect(draft.warnings.any((w) => w.contains('92 - 97')), isFalse);
    },
  );
  test('type detection requires semantic evidence, not range magnitude', () {
    const parser = SizeChartParser();
    final unknown = parser.parse('cm\nSIZE LINGKAR DADA\nM 92-97');
    expect(unknown.basis, isNull);
    expect(unknown.rows.single.chest, '92-97');
    expect(
      () => unknown.confirm(imagePath: '/x.png', ocrText: ''),
      throwsFormatException,
    );
    final garment = parser.parse(
      'GARMENT MEASUREMENTS RENTANG: TOLERANSI cm\nSIZE LINGKAR DADA\nM 100-104',
    );
    expect(garment.basis, ChartBasis.garment);
    expect(garment.rangeMeaning, ChartRangeMeaning.variation);
    expect(
      garment
          .confirm(imagePath: '/x.png', ocrText: '')
          .sizes
          .single
          .chestCm
          .max,
      104,
    );
    final conflicting = parser.parse(
      'BODY MEASUREMENTS GARMENT MEASUREMENTS cm\nSIZE DADA\nM 92-97',
    );
    expect(conflicting.basis, isNull);
    expect(conflicting.rows, hasLength(1));
    final footnote = parser.parse(
      'GARMENT MEASUREMENTS TOLERANSI 1-2 cm\nSIZE LINGKAR DADA\nM 90-120',
    );
    expect(footnote.rows.single.chest, '90-120');
    expect(footnote.rangeMeaning, isNull);
  });
}

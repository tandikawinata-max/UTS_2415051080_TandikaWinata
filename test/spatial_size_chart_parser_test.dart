import 'package:flutter_test/flutter_test.dart';
import 'package:usize/models/ocr_document.dart';
import 'package:usize/models/reviewed_size_chart.dart';
import 'package:usize/services/size_chart_parser.dart';

OcrToken token(String text, double x, double y, {double width = 30}) =>
    OcrToken(
      text: text,
      left: x - width / 2,
      right: x + width / 2,
      top: y - 8,
      bottom: y + 8,
    );
OcrDocument doc(List<OcrToken> tokens, {String? text}) => OcrDocument(
  text: text ?? 'UKURAN PAKAIAN\n${tokens.map((t) => t.text).join('\n')}\ncm',
  tokens: tokens.reversed.toList(),
);

void main() {
  const parser = SizeChartParser();
  test(
    'OCR order does not determine row/column order; missing cells never shift',
    () {
      final result = parser.parseDocument(
        doc([
          token('SIZE', 40, 20),
          token('Lingkar dada', 160, 20),
          token('Lingkar pinggang', 280, 20),
          token('Bahu', 400, 20),
          token('S', 40, 60),
          token('92', 160, 60),
          token('76', 280, 60),
          token('38', 400, 60),
          token('M', 40, 100),
          token('100', 160, 100),
          token('40', 400, 100),
          token('L', 40, 140),
          token('104', 160, 140),
          token('90', 280, 140),
          token('42', 400, 140),
        ]),
      );
      expect(result.rows.map((r) => r.label), ['S', 'M', 'L']);
      expect(result.rows[1].chest, '100');
      expect(result.rows[1].waist, isEmpty);
      expect(result.rows[1].shoulder, '40');
      expect(result.unit, ChartUnit.cm);
      expect(result.chestType, ChartMeasureType.circumference);
      expect(result.waistType, ChartMeasureType.circumference);
    },
  );
  test('transposed chart keeps missing middle cell under its size', () {
    final result = parser.parseDocument(
      doc([
        token('Ukuran', 40, 20),
        token('S', 160, 20),
        token('M', 280, 20),
        token('L', 400, 20),
        token('Lebar dada', 40, 60),
        token('46', 160, 60),
        token('50', 280, 60),
        token('52', 400, 60),
        token('Bahu', 40, 100),
        token('38', 160, 100),
        token('42', 400, 100),
      ]),
    );
    expect(result.rows[1].chest, '50');
    expect(result.rows[1].shoulder, isEmpty);
    expect(result.rows[2].shoulder, '42');
    expect(result.chestType, ChartMeasureType.flatWidth);
    expect(
      result.confirm(imagePath: '/chart.png', ocrText: '').sizes[1].chestCm.min,
      100,
    );
  });
  test('unknown and ignored columns do not shift known measurements', () {
    final result = parser.parseDocument(
      doc([
        token('Size', 40, 20),
        token('Chest width', 160, 20),
        token('Harga', 280, 20),
        token('Bahu', 400, 20),
        token('M', 40, 60),
        token('50', 160, 60),
        token('250', 280, 60),
        token('40', 400, 60),
      ]),
    );
    expect(result.rows.single.chest, '50');
    expect(result.rows.single.shoulder, '40');
  });
  test(
    'numeric sizes require a size heading and are supported in both orientations',
    () {
      final result = parser.parseDocument(
        doc([
          token('Size', 40, 20),
          token('Lingkar dada', 160, 20),
          token('38', 40, 60),
          token('96', 160, 60),
          token('40', 40, 100),
          token('100', 160, 100),
        ]),
      );
      expect(result.rows.map((r) => r.label), ['38', '40']);
      final transposed = parser.parseDocument(
        doc([
          token('Size', 40, 20),
          token('38', 160, 20),
          token('40', 280, 20),
          token('Lingkar dada', 40, 60),
          token('96', 160, 60),
          token('100', 280, 60),
        ]),
      );
      expect(transposed.rows.map((r) => r.chest), ['96', '100']);
    },
  );
  test(
    'split header words and vertically wrapped headers are reconstructed',
    () {
      final result = parser.parseDocument(
        doc([
          token('Size', 40, 20),
          token('Lingkar', 160, 20),
          token('Bahu', 280, 20),
          token('Dada', 160, 40),
          token('M', 40, 80),
          token('100', 160, 80),
          token('40', 280, 80),
        ]),
      );
      expect(result.rows.single.chest, '100');
      expect(result.rows.single.shoulder, '40');
      expect(result.chestType, ChartMeasureType.circumference);
      final split = parser.parseDocument(
        doc([
          token('Size', 40, 20),
          token('Lebar', 143, 20),
          token('dada', 177, 20),
          token('M', 40, 60),
          token('50', 160, 60),
        ]),
      );
      expect(split.rows.single.chest, '50');
    },
  );
  test(
    'ranges, decimals, and conflicting numbers remain visible for correction',
    () {
      final result = parser.parseDocument(
        doc([
          token('Size', 40, 20),
          token('Chest', 160, 20),
          token('Bahu', 280, 20),
          token('M', 40, 60),
          token('90-96', 160, 60),
          token('40,5', 280, 60),
        ]),
      );
      expect(result.rows.single.chest, '90-96');
      expect(result.rows.single.shoulder, '40,5');
      expect(result.warnings, isNotEmpty);
      expect(result.chestType, isNull);
    },
  );
  test('unit or measurement meaning is never guessed from magnitude', () {
    final result = parser.parse('SIZE DADA\nM 50');
    expect(result.unit, isNull);
    expect(result.chestType, isNull);
    expect(
      () => result.confirm(imagePath: '/chart.png', ocrText: ''),
      throwsFormatException,
    );
  });
  test('explicit inches inferred and source numbers preserved', () {
    final result = parser.parseDocument(
      doc([
        token('Size', 40, 20),
        token('Chest width', 160, 20),
        token('Shoulder', 280, 20),
        token('M', 40, 60),
        token('20', 160, 60),
        token('16', 280, 60),
      ], text: 'UKURAN PAKAIAN\nSize Chest width Shoulder\nM 20 16\nINCH'),
    );
    final chart = result.confirm(imagePath: '/chart.png', ocrText: '');
    expect(chart.sizes.single.chestCm.min, closeTo(101.6, .00001));
    expect(chart.sizes.single.shoulderWidthCm!.min, closeTo(40.64, .00001));
    expect(chart.inputRows.single.chest, '20');
  });
  test(
    'mixed units and multiple tables need correction; body charts are retained',
    () {
      expect(parser.parse('SIZE LINGKAR DADA\nM 100\ncm inch').rows, isEmpty);
      expect(
        parser.parse('BODY MEASUREMENTS\nSIZE DADA\nM 100 cm').basis,
        ChartBasis.body,
      );
      final result = parser.parseDocument(
        doc([
          token('Size', 40, 20),
          token('Chest', 160, 20),
          token('M', 40, 60),
          token('100', 160, 60),
          token('Size', 40, 100),
          token('Chest', 160, 100),
          token('M', 40, 140),
          token('101', 160, 140),
        ]),
      );
      expect(result.rows, isEmpty);
      expect(result.warnings.single, contains('Lebih dari satu tabel'));
    },
  );
}

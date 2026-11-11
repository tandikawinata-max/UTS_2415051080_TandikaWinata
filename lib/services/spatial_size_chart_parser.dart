import 'dart:math' as math;

import '../models/ocr_document.dart';
import '../models/reviewed_size_chart.dart';

const _fieldPatterns = <String, String>{
  'chest':
      r'\b(LINGKAR\s+DADA|LEBAR\s+DADA|DADA|CHEST(?:\s+(?:WIDTH|CIRCUMFERENCE))?|BUST(?:\s+(?:WIDTH|CIRCUMFERENCE))?|LD|PIT\s+TO\s+PIT)\b',
  'waist':
      r'\b((?:LINGKAR\s+|LEBAR\s+)?PINGGANG|WAIST(?:\s+(?:WIDTH|CIRCUMFERENCE))?)\b',
  'hip':
      r'\b((?:LINGKAR\s+|LEBAR\s+)?(?:PINGGUL|PANGGUL)|HIPS?(?:\s+(?:WIDTH|CIRCUMFERENCE))?)\b',
  'shoulder': r'\b(LEBAR\s+BAHU|SHOULDERS?(?:\s+WIDTH)?|BAHU)\b',
  'ignore':
      r'\b(PANJANG(?:\s+(?:BAJU|BLOUSE|GAMIS|LENGAN))?|(?:BODY\s+|SLEEVE\s+)?LENGTH|LENGAN)\b',
};

String? _field(String text) {
  for (final entry in _fieldPatterns.entries) {
    if (RegExp(entry.value).hasMatch(text.toUpperCase())) return entry.key;
  }
  return null;
}

String _normal(String text) => text
    .toUpperCase()
    .replaceAll(RegExp(r'[^A-Z0-9.,/\s-]'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

String? _size(String text, {bool numeric = false}) {
  final value = _normal(text).replaceAll(' ', '');
  if (RegExp(
        r'^(?:XXXS|XXS|XS|S|M|L|XL|XXL|XXXL|[2-6]XL|[2-6]XS|ONESIZE|ALLSIZE)$',
      ).hasMatch(value) ||
      (numeric && RegExp(r'^\d{1,3}$').hasMatch(value))) {
    return value;
  }
  return null;
}

/// Metadata is inferred only from explicit wording, never from numeric magnitude.
SizeChartDraft enrichChartDraft(SizeChartDraft draft, String text) {
  final source = text.toUpperCase();
  final warnings = [...draft.warnings];
  final hasCm = RegExp(
    r'\b(CM|SENTIMETER|CENTIMETERS?|CENTIMETRES?)\b',
  ).hasMatch(source);
  final hasInch = RegExp(r'\b(INCH(?:ES)?|INCI)\b').hasMatch(source);
  final unit = hasCm == hasInch
      ? null
      : hasCm
      ? ChartUnit.cm
      : ChartUnit.inch;
  if (hasCm && hasInch) {
    return SizeChartDraft(
      rows: [],
      warnings: [
        'Gambar memuat cm dan inci. Pilih screenshot satu tabel dengan satu satuan, '
            'atau masukkan ulang angka dalam satu satuan melalui input manual.',
      ],
    );
  }
  final hasBody = RegExp(
    r'\b(BODY MEASUREMENTS?|BODY SIZE|UKURAN TUBUH|UKURAN BADAN|LINGKAR TUBUH)\b',
  ).hasMatch(source);
  final hasGarment = RegExp(
    r'\b(GARMENT MEASUREMENTS?|PRODUCT MEASUREMENTS?|UKURAN PAKAIAN|UKURAN BAJU|UKURAN PRODUK|MEASURED FLAT|DIUKUR MENDATAR|PIT TO PIT)\b',
  ).hasMatch(source);
  final basis = hasBody == hasGarment
      ? null
      : hasBody
      ? ChartBasis.body
      : ChartBasis.garment;
  // A generic tolerance footnote does not explain what a cell's range means.
  final variation = RegExp(
    r'\bRENTANG(?:\s+UKURAN)?\s*(?::|MENUNJUKKAN|ADALAH|MERUPAKAN)\s*(?:VARIASI|TOLERANSI)\b|\bRANGES?\s*(?::|INDICATES?|REPRESENTS?)\s*(?:MEASUREMENT\s+|PRODUCTION\s+)?(?:VARIATION|TOLERANCE)\b',
  ).hasMatch(source);
  final stretch = RegExp(
    r'RELAXED[\s\S]{0,30}STRETCHED|SEBELUM[\s\S]{0,30}SESUDAH[\s\S]{0,20}(DIREGANGKAN|DITARIK)|TANPA[\s\S]{0,20}DITARIK[\s\S]{0,30}(MAKSIMAL|DIREGANGKAN)',
  ).hasMatch(source);
  final rangeMeaning = variation == stretch
      ? null
      : variation
      ? ChartRangeMeaning.variation
      : ChartRangeMeaning.stretch;
  final globalFlat = RegExp(
    r'\b(MEASURED FLAT|FLAT MEASUREMENTS|DIUKUR MENDATAR|SEMUA UKURAN LEBAR BENTANG)\b',
  ).hasMatch(source);
  final globalCircle = RegExp(
    r'\b(ALL MEASUREMENTS ARE CIRCUMFERENCES|SEMUA UKURAN LINGKAR)\b',
  ).hasMatch(source);
  ChartMeasureType? type(String field) {
    final matches = RegExp(_fieldPatterns[field]!).allMatches(source);
    final detected = <ChartMeasureType>{};
    for (final match in matches) {
      final words = match.group(0)!;
      if (words.contains('LINGKAR') || words.contains('CIRCUMFERENCE')) {
        detected.add(ChartMeasureType.circumference);
      }
      if (words.contains('LEBAR') ||
          words.contains('WIDTH') ||
          words.contains('PIT TO PIT')) {
        detected.add(ChartMeasureType.flatWidth);
      }
    }
    if (globalFlat) detected.add(ChartMeasureType.flatWidth);
    if (globalCircle) detected.add(ChartMeasureType.circumference);
    return detected.length == 1 ? detected.single : null;
  }

  final chest = basis == ChartBasis.body
      ? ChartMeasureType.circumference
      : type('chest');
  final waist = basis == ChartBasis.body
      ? ChartMeasureType.circumference
      : type('waist');
  final hip = basis == ChartBasis.body
      ? ChartMeasureType.circumference
      : type('hip');
  if (basis == null && draft.rows.isNotEmpty) {
    warnings.add(
      'Jenis tabel belum jelas. Pilih ukuran tubuh atau ukuran pakaian jadi; angka tetap tersedia.',
    );
  }
  if (basis == ChartBasis.garment &&
      draft.rows.any((row) => row.hasRange) &&
      rangeMeaning == null) {
    warnings.add(
      'Konfirmasi apakah rentang pakaian menunjukkan variasi ukuran atau regangan.',
    );
  }
  if (unit == null) {
    warnings.add('Satuan belum terbaca jelas. Pilih cm atau inci.');
  }
  if (chest == null && draft.rows.isNotEmpty) {
    warnings.add('Pastikan dada berupa lingkar atau lebar bentang.');
  }
  if (waist == null && draft.rows.any((r) => r.waist.isNotEmpty)) {
    warnings.add('Pastikan pinggang berupa lingkar atau lebar bentang.');
  }
  if (hip == null && draft.rows.any((r) => r.hip.isNotEmpty)) {
    warnings.add('Pastikan pinggul berupa lingkar atau lebar bentang.');
  }
  return SizeChartDraft(
    rows: draft.rows,
    warnings: warnings,
    unit: unit,
    basis: basis,
    rangeMeaning: rangeMeaning,
    chestType: chest,
    waistType: waist,
    hipType: hip,
  );
}

class _Cell {
  final String text;
  final double left, right, top, bottom;
  const _Cell(this.text, this.left, this.right, this.top, this.bottom);
  double get x => (left + right) / 2;
  double get y => (top + bottom) / 2;
  double get height => bottom - top;
  _Cell join(_Cell other) => _Cell(
    '$text ${other.text}',
    math.min(left, other.left),
    math.max(right, other.right),
    math.min(top, other.top),
    math.max(bottom, other.bottom),
  );
}

class _Axis {
  final _Cell cell;
  final String key;
  const _Axis(this.cell, this.key);
}

/// Reconstructs upright tables by spatial rows and column centres.
/// Empty cells stay empty. Unknown columns remain barriers, avoiding shifts.
class SpatialSizeChartParser {
  const SpatialSizeChartParser();

  List<List<_Cell>> _rows(List<OcrToken> tokens) {
    final cells =
        tokens
            .where(
              (t) =>
                  t.text.trim().isNotEmpty &&
                  t.height > 0 &&
                  t.right > t.left &&
                  t.x.isFinite &&
                  t.y.isFinite,
            )
            .map((t) => _Cell(t.text.trim(), t.left, t.right, t.top, t.bottom))
            .toList()
          ..sort((a, b) => a.y.compareTo(b.y));
    final rows = <List<_Cell>>[];
    for (final cell in cells) {
      if (rows.isEmpty ||
          (cell.y - rows.last.first.y).abs() >
              math.min(cell.height, rows.last.first.height) * 0.55) {
        rows.add([cell]);
      } else {
        rows.last.add(cell);
      }
    }
    for (final row in rows) {
      row.sort((a, b) => a.x.compareTo(b.x));
    }
    return rows;
  }

  List<_Cell> _phrases(List<_Cell> row) {
    final result = <_Cell>[];
    for (var i = 0; i < row.length; i++) {
      var cell = row[i];
      // Only merge adjacent words when the entire phrase is a known heading.
      for (var j = i + 1; j < row.length && j <= i + 3; j++) {
        if (row[j].left - cell.right >
            math.max(cell.height, row[j].height) * 1.6) {
          break;
        }
        final joined = cell.join(row[j]);
        final text = _normal(joined.text);
        final known =
            _fieldPatterns.values.any(
              (p) => RegExp('^(?:$p)\$').hasMatch(text),
            ) ||
            text == 'ONE SIZE' ||
            text == 'ALL SIZE';
        if (known) {
          cell = joined;
          i = j;
          break;
        }
        // Permit prefixes such as PIT TO before the final word PIT.
        if (!RegExp(r'^(PIT TO)$').hasMatch(text)) break;
        cell = joined;
      }
      result.add(cell);
    }
    return result;
  }

  List<List<_Cell>> _mergeHeaderBands(List<List<_Cell>> rows) {
    bool headingRow(List<_Cell> row) =>
        row.any(
          (c) =>
              _field(c.text) != null ||
              RegExp(
                r'^(SIZE|UKURAN|LINGKAR|LEBAR)$',
              ).hasMatch(_normal(c.text)),
        ) &&
        !row.any((c) => _size(c.text, numeric: true) != null);
    final result = <List<_Cell>>[];
    for (final row in rows) {
      if (result.isEmpty ||
          !headingRow(result.last) ||
          !headingRow(row) ||
          row.first.top - result.last.map((c) => c.bottom).reduce(math.max) >
              row.first.height * 1.5) {
        result.add([...row]);
        continue;
      }
      final combined = [...result.last];
      var valid = true;
      for (final cell in row) {
        final aligned = combined.indexWhere(
          (c) => (c.x - cell.x).abs() <= math.max(c.height, cell.height) * 1.4,
        );
        if (aligned < 0) {
          combined.add(cell);
          continue;
        }
        final joined = combined[aligned].join(cell);
        final text = _normal(joined.text);
        if (_fieldPatterns.values.any(
          (p) => RegExp('^(?:$p)\$').hasMatch(text),
        )) {
          combined[aligned] = joined;
        } else {
          valid = false;
          break;
        }
      }
      if (valid) {
        combined.sort((a, b) => a.x.compareTo(b.x));
        result[result.length - 1] = combined;
      } else {
        result.add([...row]);
      }
    }
    return result;
  }

  int? _column(double x, List<_Axis> axes) {
    if (axes.isEmpty) return null;
    final leftGap = axes.length > 1 ? axes[1].cell.x - axes[0].cell.x : 120.0;
    final rightGap = axes.length > 1
        ? axes.last.cell.x - axes[axes.length - 2].cell.x
        : 120.0;
    if (x < axes.first.cell.x - leftGap / 2 ||
        x > axes.last.cell.x + rightGap / 2) {
      return null;
    }
    for (var i = 0; i < axes.length - 1; i++) {
      if (x < (axes[i].cell.x + axes[i + 1].cell.x) / 2) return i;
    }
    return axes.length - 1;
  }

  List<List<_Cell>> _buckets(List<_Cell> row, List<_Axis> axes) {
    final buckets = List.generate(axes.length, (_) => <_Cell>[]);
    for (final cell in row) {
      final index = _column(cell.x, axes);
      if (index != null) buckets[index].add(cell);
    }
    return buckets;
  }

  String _number(
    List<_Cell> cells,
    String label,
    String field,
    List<String> warnings,
  ) {
    if (cells.isEmpty) return '';
    var text = cells.map((c) => c.text).join(' ').trim();
    text = text
        .replaceAll(
          RegExp(r'\s*(cm|inch(?:es)?|inci)\s*$', caseSensitive: false),
          '',
        )
        .trim();
    if (text == '-' || text == '—') return '';
    // Keep ranges intact. Preserve malformed text for correction.
    if (SizeChartRules.number(text) != null) {
      warnings.add('Ukuran $label, $field: "$text" perlu dikoreksi.');
    }
    return text;
  }

  SizeChartDraftRow _draft(String label, Map<String, String> values) =>
      SizeChartDraftRow(
        label: label,
        chest: values['chest'] ?? '',
        waist: values['waist'] ?? '',
        hip: values['hip'] ?? '',
        shoulder: values['shoulder'] ?? '',
      );

  SizeChartDraft parse(OcrDocument document) {
    final rows = _mergeHeaderBands(
      _rows(document.tokens).map(_phrases).toList(),
    );
    final candidates = <({int index, bool transposed})>[];
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final explicitSize = row.any(
        (c) => RegExp(r'^(SIZE|UKURAN)$').hasMatch(_normal(c.text)),
      );
      final fields = row
          .where((c) => _field(c.text) != null && _field(c.text) != 'ignore')
          .length;
      final labels = row
          .where((c) => _size(c.text, numeric: explicitSize) != null)
          .length;
      if (fields > 0 && explicitSize) {
        candidates.add((index: i, transposed: false));
      } else if ((explicitSize && labels > 0) ||
          (labels >= 2 &&
              fields == 0 &&
              row.every((c) => _size(c.text) != null))) {
        candidates.add((index: i, transposed: true));
      }
    }
    if (candidates.length != 1) {
      return SizeChartDraft(
        rows: [],
        warnings: [
          candidates.isEmpty
              ? 'Judul tabel belum dikenali. Gunakan gambar tabel utuh dan tegak, atau input manual.'
              : 'Lebih dari satu tabel terdeteksi. Gunakan screenshot satu tabel saja.',
        ],
      );
    }
    final candidate = candidates.single;
    final header = rows[candidate.index];
    final warnings = <String>[];
    final result = <SizeChartDraftRow>[];
    if (!candidate.transposed) {
      final axes = header
          .map(
            (c) => _Axis(
              c,
              RegExp(r'^(SIZE|UKURAN)$').hasMatch(_normal(c.text))
                  ? 'size'
                  : _field(c.text) ?? 'ignore',
            ),
          )
          .toList();
      final used = axes
          .where((a) => a.key != 'ignore')
          .map((a) => a.key)
          .toList();
      if (used.toSet().length != used.length) {
        return SizeChartDraft(
          rows: [],
          warnings: ['Judul pengukuran berulang. Gunakan satu tabel saja.'],
        );
      }
      for (final row in rows.skip(candidate.index + 1)) {
        final buckets = _buckets(row, axes);
        final sizeIndex = axes.indexWhere((a) => a.key == 'size');
        final label = _size(
          buckets[sizeIndex].map((c) => c.text).join(' '),
          numeric: true,
        );
        if (label == null) continue;
        final values = <String, String>{};
        for (var i = 0; i < axes.length; i++) {
          final field = axes[i].key;
          if (field == 'size' || field == 'ignore') continue;
          values[field] = _number(buckets[i], label, field, warnings);
        }
        result.add(_draft(label, values));
      }
    } else {
      final explicitSize = header.any(
        (c) => RegExp(r'^(SIZE|UKURAN)$').hasMatch(_normal(c.text)),
      );
      final axes = header
          .map(
            (c) => _Axis(c, _size(c.text, numeric: explicitSize) ?? 'ignore'),
          )
          .toList();
      final values = <String, Map<String, String>>{
        for (final axis in axes)
          if (axis.key != 'ignore') axis.key: {},
      };
      if (values.length != axes.where((a) => a.key != 'ignore').length) {
        return SizeChartDraft(
          rows: [],
          warnings: ['Nama ukuran berulang. Periksa gambar sumber.'],
        );
      }
      final seen = <String>{};
      final repeated = <String>{};
      for (final row in rows.skip(candidate.index + 1)) {
        final fieldCells = row.where((c) => _field(c.text) != null).toList();
        if (fieldCells.length != 1) continue;
        final heading = fieldCells.single;
        final field = _field(heading.text)!;
        if (field == 'ignore') continue;
        final firstSize = axes.firstWhere((a) => a.key != 'ignore');
        if (heading.x >= firstSize.cell.x) continue;
        if (!seen.add(field)) {
          repeated.add(field);
          continue;
        }
        final buckets = _buckets(row.where((c) => c != heading).toList(), axes);
        for (var i = 0; i < axes.length; i++) {
          final label = axes[i].key;
          if (label == 'ignore') continue;
          values[label]![field] = _number(buckets[i], label, field, warnings);
        }
      }
      for (final field in repeated) {
        for (final value in values.values) {
          value.remove(field);
        }
        warnings.add('Baris $field berulang; periksa bagian tersebut.');
      }
      for (final entry in values.entries) {
        result.add(_draft(entry.key, entry.value));
      }
    }
    if (result.isEmpty) {
      warnings.add(
        'Baris ukuran belum dikenali. Pilih gambar lebih jelas atau gunakan input manual.',
      );
    }
    for (final row in result) {
      if (row.chest.isEmpty) {
        warnings.add('Ukuran ${row.label}: dada belum terbaca.');
      }
    }
    return enrichChartDraft(
      SizeChartDraft(rows: result, warnings: warnings),
      '${document.text}\n${rows.expand((r) => r).map((c) => c.text).join('\n')}',
    );
  }
}

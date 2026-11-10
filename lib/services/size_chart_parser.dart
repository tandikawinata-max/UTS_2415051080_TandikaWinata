import '../models/reviewed_size_chart.dart';

class SizeChartParser {
  const SizeChartParser();

  static const _fields = {'#C', '#W', '#H', '#S', '#IGNORE'};

  static final _sizePattern = RegExp(
    r'^(?:XXXS|XXS|XS|S|M|L|XL|XXL|XXXL|[2-6]XL|[2-6]XS|ONESIZE|ALLSIZE)$',
  );

  static final _numberPattern = RegExp(r'^\d+(?:[.,]\d{1,2})?$');

  static const _aliases = {
    '#C': r'\b(LINGKAR\s+DADA|LEBAR\s+DADA|DADA|CHEST|BUST|LD)\b',
    '#W': r'\b(LINGKAR\s+PINGGANG|LEBAR\s+PINGGANG|PINGGANG|WAIST)\b',
    '#H': r'\b(LINGKAR\s+PINGGUL|LEBAR\s+PINGGUL|PINGGUL|PANGGUL|HIPS?)\b',
    '#S': r'\b(LEBAR\s+BAHU|SHOULDER\s+WIDTH|SHOULDERS?|BAHU)\b',
    '#IGNORE':
        r'\b(PANJANG\s+(BAJU|BLOUSE|GAMIS|LENGAN)|BODY\s+LENGTH|SLEEVE\s+LENGTH|LENGTH)\b',
  };

  SizeChartDraft parse(String text) {
    var normalized = text.toUpperCase();

    normalized = normalized.replaceAll(
      RegExp(r'\b(?:ONE|ALL)\s+SIZE\b'),
      'ONESIZE',
    );

    for (final entry in _aliases.entries) {
      normalized = normalized.replaceAll(RegExp(entry.value), entry.key);
    }

    normalized = normalized.replaceAll(
      RegExp(r'\b(?:SIZE|UKURAN|CM|INCH|INCHES|INCI)\b'),
      ' ',
    );

    final tokens = normalized
        .split(RegExp(r'[\s|:;()]+'))
        .where((token) => token.isNotEmpty)
        .toList();

    final warnings = <String>[];

    if (tokens.contains('#IGNORE')) {
      warnings.add('Kolom panjang atau lengan tidak digunakan dalam draf ini.');
    }

    final firstSize = tokens.indexWhere(_isSize);

    if (firstSize < 0) {
      return SizeChartDraft(
        rows: [],
        warnings: [
          ...warnings,
          'Susunan ukuran belum dikenali. Isi tabel secara manual.',
        ],
      );
    }

    var afterSizes = firstSize;

    while (afterSizes < tokens.length && _isSize(tokens[afterSizes])) {
      afterSizes++;
    }

    if (afterSizes < tokens.length && _fields.contains(tokens[afterSizes])) {
      return _sizesInColumns(tokens, firstSize, afterSizes, warnings);
    }

    return _sizesInRows(tokens, firstSize, warnings);
  }

  bool _isSize(String token) => _sizePattern.hasMatch(token);

  bool _isCell(String token) {
    return token == '-' || token == '—' || _numberPattern.hasMatch(token);
  }

  String _cell(String token) {
    return token == '-' || token == '—' ? '' : token;
  }

  SizeChartDraftRow _row(String label, Map<String, String> values) {
    return SizeChartDraftRow(
      label: label,
      chest: values['#C'] ?? '',
      waist: values['#W'] ?? '',
      hip: values['#H'] ?? '',
      shoulder: values['#S'] ?? '',
    );
  }

  SizeChartDraft _sizesInColumns(
    List<String> tokens,
    int firstSize,
    int afterSizes,
    List<String> warnings,
  ) {
    final labels = tokens.sublist(firstSize, afterSizes);
    final columns = <String, List<String>>{};
    final seen = <String>{};

    var cursor = afterSizes;

    while (cursor < tokens.length) {
      final field = tokens[cursor];

      if (!_fields.contains(field)) {
        cursor++;
        continue;
      }

      var end = cursor + 1;

      while (end < tokens.length && !_fields.contains(tokens[end])) {
        end++;
      }

      final values = tokens.sublist(cursor + 1, end);
      cursor = end;

      if (field == '#IGNORE') {
        continue;
      }

      if (!seen.add(field)) {
        columns.remove(field);
        warnings.add(
          'Ada judul pengukuran berulang. Kolom terkait perlu diisi manual.',
        );
        continue;
      }

      if (values.length != labels.length || !values.every(_isCell)) {
        warnings.add(
          'Jumlah atau bentuk angka tidak cocok dengan daftar ukuran. '
          'Kolom yang meragukan dikosongkan.',
        );
        continue;
      }

      columns[field] = values.map(_cell).toList();
    }

    return SizeChartDraft(
      rows: [
        for (var i = 0; i < labels.length; i++)
          _row(labels[i], {
            for (final entry in columns.entries) entry.key: entry.value[i],
          }),
      ],
      warnings: warnings,
    );
  }

  SizeChartDraft _sizesInRows(
    List<String> tokens,
    int firstSize,
    List<String> warnings,
  ) {
    var start = firstSize - 1;

    while (start >= 0 && _fields.contains(tokens[start])) {
      start--;
    }

    final headers = tokens.sublist(start + 1, firstSize);
    final usedHeaders = headers.where((header) => header != '#IGNORE').toList();

    if (!headers.contains('#C') ||
        usedHeaders.toSet().length != usedHeaders.length) {
      return SizeChartDraft(
        rows: [],
        warnings: [
          ...warnings,
          'Judul kolom belum dapat dipetakan dengan aman. '
              'Isi tabel secara manual.',
        ],
      );
    }

    final rows = <SizeChartDraftRow>[];
    var cursor = firstSize;

    while (cursor < tokens.length) {
      if (!_isSize(tokens[cursor])) {
        cursor++;
        continue;
      }

      final label = tokens[cursor];
      var end = cursor + 1;

      while (end < tokens.length && !_isSize(tokens[end])) {
        end++;
      }

      final values = tokens.sublist(cursor + 1, end);
      cursor = end;

      if (values.length != headers.length || !values.every(_isCell)) {
        rows.add(SizeChartDraftRow(label: label));
        warnings.add(
          'Angka untuk ukuran $label belum dapat dipetakan. '
          'Isi ulang dari gambar.',
        );
        continue;
      }

      rows.add(
        _row(label, {
          for (var i = 0; i < headers.length; i++)
            if (headers[i] != '#IGNORE') headers[i]: _cell(values[i]),
        }),
      );
    }

    return SizeChartDraft(rows: rows, warnings: warnings);
  }
}

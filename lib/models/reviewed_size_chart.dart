enum ChartUnit {
  cm,
  inch;

  String get label => this == ChartUnit.cm ? 'Sentimeter (cm)' : 'Inci (inch)';

  String get symbol => this == ChartUnit.cm ? 'cm' : 'inch';

  double get cmFactor => this == ChartUnit.cm ? 1.0 : 2.54;
}

enum ChartMeasureType {
  circumference,
  flatWidth;

  String get label => this == ChartMeasureType.circumference
      ? 'Lingkar penuh'
      : 'Lebar bentang (×2)';
}

class SizeChartDraftRow {
  final String label;
  final String chest;
  final String waist;
  final String hip;
  final String shoulder;

  const SizeChartDraftRow({
    this.label = '',
    this.chest = '',
    this.waist = '',
    this.hip = '',
    this.shoulder = '',
  });

  SizeChartDraftRow copyWith({
    String? label,
    String? chest,
    String? waist,
    String? hip,
    String? shoulder,
  }) {
    return SizeChartDraftRow(
      label: label ?? this.label,
      chest: chest ?? this.chest,
      waist: waist ?? this.waist,
      hip: hip ?? this.hip,
      shoulder: shoulder ?? this.shoulder,
    );
  }
}

class SizeChartDraft {
  final List<SizeChartDraftRow> rows;
  final List<String> warnings;

  SizeChartDraft({
    required List<SizeChartDraftRow> rows,
    required List<String> warnings,
  }) : rows = List.unmodifiable(rows),
       warnings = List.unmodifiable(warnings.toSet());
}

class SizeChartRules {
  static String labelKey(String value) {
    return value.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  static String? label(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Nama ukuran wajib diisi.';
    }

    if (text.length > 20) {
      return 'Maksimal 20 karakter.';
    }

    return null;
  }

  static String? number(String? value, {bool requiredValue = false}) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return requiredValue ? 'Nilai wajib diisi.' : null;
    }

    if (!RegExp(r'^\d+(?:[.,]\d{1,2})?$').hasMatch(text)) {
      return 'Gunakan angka, maksimal 2 desimal.';
    }

    final parsed = double.tryParse(text.replaceAll(',', '.'));

    if (parsed == null || !parsed.isFinite || parsed <= 0 || parsed > 9999.99) {
      return 'Nilai harus > 0 dan ≤ 9999,99.';
    }

    return null;
  }

  static double? parseOptional(String value) {
    final text = value.trim();

    if (text.isEmpty) {
      return null;
    }

    return double.parse(text.replaceAll(',', '.'));
  }
}

class ReviewedSizeRow {
  final String label;
  final double chestCm;
  final double? waistCm;
  final double? hipCm;
  final double? shoulderWidthCm;

  const ReviewedSizeRow({
    required this.label,
    required this.chestCm,
    this.waistCm,
    this.hipCm,
    this.shoulderWidthCm,
  });
}

class ReviewedSizeChart {
  final String sourceImagePath;
  final String sourceOcrText;
  final ChartUnit unit;
  final ChartMeasureType chestType;
  final ChartMeasureType? waistType;
  final ChartMeasureType? hipType;
  final List<SizeChartDraftRow> inputRows;
  final List<ReviewedSizeRow> sizes;
  final DateTime reviewedAt;

  const ReviewedSizeChart._({
    required this.sourceImagePath,
    required this.sourceOcrText,
    required this.unit,
    required this.chestType,
    required this.waistType,
    required this.hipType,
    required this.inputRows,
    required this.sizes,
    required this.reviewedAt,
  });

  factory ReviewedSizeChart.confirm({
    required String sourceImagePath,
    required String sourceOcrText,
    required ChartUnit unit,
    required ChartMeasureType chestType,
    ChartMeasureType? waistType,
    ChartMeasureType? hipType,
    required List<SizeChartDraftRow> rows,
  }) {
    if (sourceImagePath.trim().isEmpty) {
      throw const FormatException('Screenshot sumber belum tersedia.');
    }

    if (rows.isEmpty) {
      throw const FormatException('Tambahkan minimal satu ukuran.');
    }

    final labels = <String>{};

    for (final row in rows) {
      final labelError = SizeChartRules.label(row.label);

      if (labelError != null) {
        throw FormatException(labelError);
      }

      if (!labels.add(SizeChartRules.labelKey(row.label))) {
        throw FormatException('Ukuran "${row.label.trim()}" duplikat.');
      }

      final errors = [
        SizeChartRules.number(row.chest, requiredValue: true),
        SizeChartRules.number(row.waist),
        SizeChartRules.number(row.hip),
        SizeChartRules.number(row.shoulder),
      ];

      for (final error in errors) {
        if (error != null) {
          throw FormatException('Ukuran ${row.label.trim()}: $error');
        }
      }

      if (row.waist.trim().isNotEmpty && waistType == null) {
        throw const FormatException('Pilih jenis pengukuran pinggang.');
      }

      if (row.hip.trim().isNotEmpty && hipType == null) {
        throw const FormatException('Pilih jenis pengukuran pinggul.');
      }
    }

    double? circumference(String value, ChartMeasureType? type) {
      final parsed = SizeChartRules.parseOptional(value);

      if (parsed == null) {
        return null;
      }

      final multiplier = type == ChartMeasureType.flatWidth ? 2.0 : 1.0;

      return parsed * unit.cmFactor * multiplier;
    }

    final converted = rows.map((row) {
      final shoulder = SizeChartRules.parseOptional(row.shoulder);

      return ReviewedSizeRow(
        label: row.label.trim(),
        chestCm: circumference(row.chest, chestType)!,
        waistCm: circumference(row.waist, waistType),
        hipCm: circumference(row.hip, hipType),
        shoulderWidthCm: shoulder == null ? null : shoulder * unit.cmFactor,
      );
    }).toList();

    return ReviewedSizeChart._(
      sourceImagePath: sourceImagePath,
      sourceOcrText: sourceOcrText,
      unit: unit,
      chestType: chestType,
      waistType: waistType,
      hipType: hipType,
      inputRows: List.unmodifiable(rows),
      sizes: List.unmodifiable(converted),
      reviewedAt: DateTime.now(),
    );
  }
}

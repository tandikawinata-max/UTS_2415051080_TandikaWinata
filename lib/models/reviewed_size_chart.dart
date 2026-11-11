import 'measurement_range.dart';

enum ChartUnit {
  cm,
  inch;

  String get label => this == ChartUnit.cm ? 'Sentimeter (cm)' : 'Inci (inch)';
  String get symbol => this == ChartUnit.cm ? 'cm' : 'inch';
  double get cmFactor => this == ChartUnit.cm ? 1.0 : 2.54;
}

enum ChartBasis {
  body('Ukuran tubuh yang cocok'),
  garment('Ukuran pakaian jadi');

  final String label;
  const ChartBasis(this.label);
}

enum ChartRangeMeaning {
  variation('Variasi / toleransi ukuran pakaian'),
  stretch('Sebelum–sesudah diregangkan'),
  unknown('Makna rentang belum diketahui');

  final String label;
  const ChartRangeMeaning(this.label);
}

enum ChartMeasureType {
  circumference,
  flatWidth;

  String get label => this == ChartMeasureType.circumference
      ? 'Lingkar penuh'
      : 'Lebar bentang (×2)';
}

class SizeChartDraftRow {
  final String label, chest, waist, hip, shoulder;
  const SizeChartDraftRow({
    this.label = '',
    this.chest = '',
    this.waist = '',
    this.hip = '',
    this.shoulder = '',
  });
  List<String> get measurements => [chest, waist, hip, shoulder];
  bool get hasRange => measurements.any(
    (value) =>
        SizeChartRules.number(value) == null &&
        (SizeChartRules.parseOptional(value)?.isRange ?? false),
  );
  SizeChartDraftRow copyWith({
    String? label,
    String? chest,
    String? waist,
    String? hip,
    String? shoulder,
  }) => SizeChartDraftRow(
    label: label ?? this.label,
    chest: chest ?? this.chest,
    waist: waist ?? this.waist,
    hip: hip ?? this.hip,
    shoulder: shoulder ?? this.shoulder,
  );
}

class SizeChartDraft {
  final List<SizeChartDraftRow> rows;
  final List<String> warnings;
  final ChartUnit? unit;
  final ChartBasis? basis;
  final ChartRangeMeaning? rangeMeaning;
  final ChartMeasureType? chestType, waistType, hipType;
  SizeChartDraft({
    required List<SizeChartDraftRow> rows,
    required List<String> warnings,
    this.unit,
    this.basis,
    this.rangeMeaning,
    this.chestType,
    this.waistType,
    this.hipType,
  }) : rows = List.unmodifiable(rows),
       warnings = List.unmodifiable(warnings.toSet());

  ReviewedSizeChart confirm({
    required String imagePath,
    required String ocrText,
  }) {
    if (unit == null) {
      throw const FormatException('Satuan belum jelas. Pilih cm atau inci.');
    }
    if (basis == null) {
      throw const FormatException(
        'Pilih jenis tabel: ukuran tubuh atau ukuran pakaian jadi.',
      );
    }
    return ReviewedSizeChart.confirm(
      sourceImagePath: imagePath,
      sourceOcrText: ocrText,
      unit: unit!,
      basis: basis!,
      rangeMeaning: rangeMeaning,
      chestType: chestType,
      waistType: waistType,
      hipType: hipType,
      rows: rows,
    );
  }
}

class SizeChartRules {
  static final _pattern = RegExp(
    r'^(\d+(?:[.,]\d{1,2})?)(?:\s*-\s*(\d+(?:[.,]\d{1,2})?))?$',
  );
  static String normalize(String value) =>
      value.replaceAll(RegExp(r'[\u2010-\u2015\u2212\uFF0D]'), '-').trim();
  static bool isEmptyValue(String value) {
    final text = normalize(value);
    return text.isEmpty || text == '-';
  }

  static String labelKey(String value) =>
      value.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');
  static String? label(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Nama ukuran wajib diisi.';
    if (text.length > 20) return 'Maksimal 20 karakter.';
    return null;
  }

  static String? number(String? value, {bool requiredValue = false}) {
    final text = normalize(value ?? '');
    if (isEmptyValue(text)) {
      return requiredValue ? 'Nilai wajib tersedia.' : null;
    }
    final match = _pattern.firstMatch(text);
    if (match == null) {
      return 'Masukkan angka atau rentang, contoh 94 atau 92–97 (maks. 2 desimal).';
    }
    final low = double.parse(match.group(1)!.replaceAll(',', '.'));
    final high = double.parse(
      (match.group(2) ?? match.group(1))!.replaceAll(',', '.'),
    );
    if (!low.isFinite || !high.isFinite || low <= 0 || high > 9999.99) {
      return 'Nilai harus > 0 dan ≤ 9999,99.';
    }
    if (low > high) return 'Batas minimum tidak boleh melebihi maksimum.';
    return null;
  }

  static MeasurementRange? parseOptional(String value) {
    final error = number(value);
    if (error != null) throw FormatException(error);
    final text = normalize(value);
    if (isEmptyValue(text)) return null;
    final match = _pattern.firstMatch(text)!;
    final min = double.parse(match.group(1)!.replaceAll(',', '.'));
    final upper = match.group(2);
    return upper == null
        ? MeasurementRange.single(min)
        : MeasurementRange.interval(
            min,
            double.parse(upper.replaceAll(',', '.')),
          );
  }
}

class ReviewedSizeRow {
  final String label;
  final MeasurementRange chestCm;
  final MeasurementRange? waistCm, hipCm, shoulderWidthCm;
  const ReviewedSizeRow({
    required this.label,
    required this.chestCm,
    this.waistCm,
    this.hipCm,
    this.shoulderWidthCm,
  });
}

class ReviewedSizeChart {
  final String sourceImagePath, sourceOcrText;
  final ChartUnit unit;
  final ChartBasis basis;
  final ChartRangeMeaning? rangeMeaning;
  final ChartMeasureType chestType;
  final ChartMeasureType? waistType, hipType;
  final List<SizeChartDraftRow> inputRows;
  final List<ReviewedSizeRow> sizes;
  final DateTime reviewedAt;
  const ReviewedSizeChart._({
    required this.sourceImagePath,
    required this.sourceOcrText,
    required this.unit,
    required this.basis,
    required this.rangeMeaning,
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
    required ChartBasis basis,
    ChartRangeMeaning? rangeMeaning,
    ChartMeasureType? chestType,
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
    final isBody = basis == ChartBasis.body;
    final labels = <String>{};
    for (final row in rows) {
      final labelError = SizeChartRules.label(row.label);
      if (labelError != null) throw FormatException(labelError);
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
      if (!isBody) {
        if (chestType == null) {
          throw const FormatException('Pilih jenis pengukuran dada.');
        }
        if (!SizeChartRules.isEmptyValue(row.waist) && waistType == null) {
          throw const FormatException('Pilih jenis pengukuran pinggang.');
        }
        if (!SizeChartRules.isEmptyValue(row.hip) && hipType == null) {
          throw const FormatException('Pilih jenis pengukuran pinggul.');
        }
      }
    }
    if (isBody &&
        [chestType, waistType, hipType].contains(ChartMeasureType.flatWidth)) {
      throw const FormatException(
        'Tabel tubuh menggunakan lingkar; lebar bentang hanya untuk pakaian.',
      );
    }
    if (!isBody && rows.any((row) => row.hasRange) && rangeMeaning == null) {
      throw const FormatException(
        'Pilih makna rentang pakaian; pilih belum diketahui jika keterangannya tidak tersedia.',
      );
    }
    MeasurementRange? convert(String value, ChartMeasureType? type) =>
        SizeChartRules.parseOptional(value)?.scale(
          unit.cmFactor *
              (!isBody && type == ChartMeasureType.flatWidth ? 2 : 1),
        );
    final converted = rows
        .map(
          (row) => ReviewedSizeRow(
            label: row.label.trim(),
            chestCm: convert(row.chest, chestType)!,
            waistCm: convert(row.waist, waistType),
            hipCm: convert(row.hip, hipType),
            shoulderWidthCm: convert(row.shoulder, null),
          ),
        )
        .toList();
    return ReviewedSizeChart._(
      sourceImagePath: sourceImagePath,
      sourceOcrText: sourceOcrText,
      unit: unit,
      basis: basis,
      rangeMeaning: isBody ? null : rangeMeaning,
      chestType: isBody ? ChartMeasureType.circumference : chestType!,
      waistType: isBody ? ChartMeasureType.circumference : waistType,
      hipType: isBody ? ChartMeasureType.circumference : hipType,
      inputRows: List.unmodifiable(rows),
      sizes: List.unmodifiable(converted),
      reviewedAt: DateTime.now(),
    );
  }
}

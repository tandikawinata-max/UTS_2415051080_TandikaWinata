enum MeasurementUnit { centimeter, inch }

enum SizeChartType {
  bodyRange,
  garmentCircumference,
  flatGarmentWidth,
  unknown,
}

enum MeasurementDimension {
  chestCircumference,
  waistCircumference,
  hipCircumference,
  shoulderWidth,
  chestWidth,
  waistWidth,
  hipWidth,
}

class MeasurementRange {
  final double min;
  final double max;

  const MeasurementRange({required this.min, required this.max});
}

class SizeChartRow {
  final String sizeLabel;
  final Map<MeasurementDimension, MeasurementRange> measurements;

  SizeChartRow({
    required this.sizeLabel,
    required Map<MeasurementDimension, MeasurementRange> measurements,
  }) : measurements = Map.unmodifiable(measurements);
}

class SizeChart {
  final String id;
  final String productName;
  final MeasurementUnit unit;
  final SizeChartType type;
  final List<SizeChartRow> rows;
  final bool isVerified;

  SizeChart({
    required this.id,
    required this.productName,
    required this.unit,
    required this.type,
    required List<SizeChartRow> rows,
    this.isVerified = false,
  }) : rows = List.unmodifiable(rows);
}

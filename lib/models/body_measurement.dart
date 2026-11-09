class BodyMeasurement {
  final String id;
  final String label;
  final double chestCm;
  final double? waistCm;
  final double? hipCm;
  final double? shoulderWidthCm;
  final double? heightCm;
  final double? weightKg;
  final DateTime measuredAt;

  const BodyMeasurement({
    required this.id,
    required this.label,
    required this.chestCm,
    this.waistCm,
    this.hipCm,
    this.shoulderWidthCm,
    this.heightCm,
    this.weightKg,
    required this.measuredAt,
  });
}

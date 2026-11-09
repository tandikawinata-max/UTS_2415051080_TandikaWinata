class BodyMeasurement {
  final String id;
  final String? userId;
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
    this.userId,
    required this.label,
    required this.chestCm,
    this.waistCm,
    this.hipCm,
    this.shoulderWidthCm,
    this.heightCm,
    this.weightKg,
    required this.measuredAt,
  });

  factory BodyMeasurement.fromJson(Map<String, dynamic> json) {
    return BodyMeasurement(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      label: json['label'] as String,
      chestCm: (json['chest_cm'] as num).toDouble(),
      waistCm: (json['waist_cm'] as num?)?.toDouble(),
      hipCm: (json['hip_cm'] as num?)?.toDouble(),
      shoulderWidthCm: (json['shoulder_width_cm'] as num?)?.toDouble(),
      heightCm: (json['height_cm'] as num?)?.toDouble(),
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      measuredAt: DateTime.parse(json['measured_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'id': id,
      'label': label.trim(),
      'chest_cm': chestCm,
      'waist_cm': waistCm,
      'hip_cm': hipCm,
      'shoulder_width_cm': shoulderWidthCm,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'measured_at': measuredAt.toUtc().toIso8601String(),
    };
  }
}

class MeasurementSaveConflict implements Exception {
  const MeasurementSaveConflict();
}

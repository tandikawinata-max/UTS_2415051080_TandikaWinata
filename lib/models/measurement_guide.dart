class MeasurementGuide {
  final String id;
  final String measurementKey;
  final String title;
  final String instruction;
  final String unit;
  final String category;
  final int sortOrder;

  const MeasurementGuide({
    required this.id,
    required this.measurementKey,
    required this.title,
    required this.instruction,
    required this.unit,
    required this.category,
    required this.sortOrder,
  });

  factory MeasurementGuide.fromJson(Map<String, dynamic> json) {
    return MeasurementGuide(
      id: json['id'] as String,
      measurementKey: json['measurement_key'] as String,
      title: json['title'] as String,
      instruction: json['instruction'] as String,
      unit: json['unit'] as String,
      category: json['category'] as String,
      sortOrder: json['sort_order'] as int,
    );
  }
}

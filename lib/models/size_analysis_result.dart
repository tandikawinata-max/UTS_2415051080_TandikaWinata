import 'measurement_range.dart';
import 'body_measurement.dart';
import 'reviewed_size_chart.dart';

enum FitPreference {
  closeFit('Rapat', 2, 4),
  regular('Reguler', 4, 10),
  relaxed('Longgar', 10, 18);

  final String label;
  final double minEaseCm, maxEaseCm;
  const FitPreference(this.label, this.minEaseCm, this.maxEaseCm);
  double get targetEaseCm => (minEaseCm + maxEaseCm) / 2;
}

enum FitDimension {
  chest('Dada'),
  waist('Pinggang'),
  hip('Pinggul'),
  shoulder('Bahu');

  final String label;
  const FitDimension(this.label);
}

enum DimensionFitStatus {
  belowTarget('Di bawah target'),
  withinTarget('Dalam target'),
  aboveTarget('Di atas target'),
  partialTarget('Sebagian rentang memenuhi target'),
  needsContext('Makna ukuran belum cukup jelas'),
  missing('Data belum tersedia'),
  informational('Informasi tambahan');

  final String label;
  const DimensionFitStatus(this.label);
}

enum SizeFitVerdict {
  meetsTarget('Memenuhi target'),
  outsideTarget('Di luar target'),
  insufficientData('Data belum lengkap'),
  partialTarget('Sebagian rentang memenuhi target'),
  needsContext('Perlu informasi tambahan');

  final String label;
  const SizeFitVerdict(this.label);
}

class DimensionComparison {
  final FitDimension dimension;
  final double? bodyCm;
  final MeasurementRange? chartCm;
  final bool usedForDecision;
  final DimensionFitStatus status;
  const DimensionComparison({
    required this.dimension,
    required this.bodyCm,
    required this.chartCm,
    required this.usedForDecision,
    required this.status,
  });
  MeasurementRange? get differenceCm =>
      bodyCm == null ? null : chartCm?.subtract(bodyCm!);
}

class SizeEvaluation {
  final String label;
  final List<DimensionComparison> comparisons;
  final SizeFitVerdict verdict;
  final double? distanceFromTargetCm;
  SizeEvaluation({
    required this.label,
    required List<DimensionComparison> comparisons,
    required this.verdict,
    required this.distanceFromTargetCm,
  }) : comparisons = List.unmodifiable(comparisons);
  bool get hasMissingRequiredData => comparisons.any(
    (c) => c.usedForDecision && (c.bodyCm == null || c.chartCm == null),
  );
}

class SizeAnalysisResult {
  final String id, ruleVersion;
  final DateTime analyzedAt;
  final BodyMeasurement profile;
  final ReviewedSizeChart chart;
  final FitPreference preference;
  final List<FitDimension> requiredDimensions;
  final List<SizeEvaluation> evaluations;
  final List<String> recommendedLabels, notes;
  SizeAnalysisResult({
    required this.id,
    required this.ruleVersion,
    required this.analyzedAt,
    required this.profile,
    required this.chart,
    required this.preference,
    required List<FitDimension> requiredDimensions,
    required List<SizeEvaluation> evaluations,
    required List<String> recommendedLabels,
    required List<String> notes,
  }) : requiredDimensions = List.unmodifiable(requiredDimensions),
       evaluations = List.unmodifiable(evaluations),
       recommendedLabels = List.unmodifiable(recommendedLabels),
       notes = List.unmodifiable(notes);
}

import 'dart:math' as math;

import '../models/body_measurement.dart';
import '../models/measurement_range.dart';
import '../models/reviewed_size_chart.dart';
import '../models/size_analysis_result.dart';

class SizeAnalysisService {
  const SizeAnalysisService();
  static const ruleVersion = 'usize-fit-v2-ranges';
  static const _epsilon = 0.000001;

  Map<FitDimension, MeasurementRange?> _values(ReviewedSizeRow row) => {
    FitDimension.chest: row.chestCm,
    FitDimension.waist: row.waistCm,
    FitDimension.hip: row.hipCm,
    FitDimension.shoulder: row.shoulderWidthCm,
  };

  DimensionFitStatus _status(
    double? body,
    MeasurementRange? value,
    bool used,
    ReviewedSizeChart chart,
    FitPreference fit,
  ) {
    if (body == null || value == null) return DimensionFitStatus.missing;
    if (!used) return DimensionFitStatus.informational;
    if (chart.basis == ChartBasis.body) {
      // A single nominal body size does not state an accepted body-size interval.
      if (!value.isRange) return DimensionFitStatus.needsContext;
      if (body < value.min - _epsilon) return DimensionFitStatus.belowTarget;
      if (body > value.max + _epsilon) return DimensionFitStatus.aboveTarget;
      return DimensionFitStatus.withinTarget;
    }
    if (value.isRange && chart.rangeMeaning != ChartRangeMeaning.variation) {
      return DimensionFitStatus.needsContext;
    }
    final difference = value.subtract(body);
    if (difference.min >= fit.minEaseCm - _epsilon &&
        difference.max <= fit.maxEaseCm + _epsilon) {
      return DimensionFitStatus.withinTarget;
    }
    if (difference.max < fit.minEaseCm - _epsilon) {
      return DimensionFitStatus.belowTarget;
    }
    if (difference.min > fit.maxEaseCm + _epsilon) {
      return DimensionFitStatus.aboveTarget;
    }
    return DimensionFitStatus.partialTarget;
  }

  SizeAnalysisResult analyze({
    required String id,
    required BodyMeasurement profile,
    required ReviewedSizeChart chart,
    required FitPreference preference,
    DateTime? analyzedAt,
  }) {
    if (chart.sizes.isEmpty) {
      throw const FormatException('Tabel ukuran masih kosong.');
    }
    final body = <FitDimension, double?>{
      FitDimension.chest: profile.chestCm,
      FitDimension.waist: profile.waistCm,
      FitDimension.hip: profile.hipCm,
      FitDimension.shoulder: profile.shoulderWidthCm,
    };
    for (final value in body.values.whereType<double>()) {
      if (!value.isFinite || value <= 0) {
        throw const FormatException('Ukuran tubuh harus berupa angka positif.');
      }
    }
    for (final row in chart.sizes) {
      for (final value in _values(row).values.whereType<MeasurementRange>()) {
        if (!value.min.isFinite ||
            !value.max.isFinite ||
            value.min <= 0 ||
            value.max < value.min) {
          throw const FormatException('Rentang tabel tidak valid.');
        }
      }
    }
    final required = <FitDimension>{FitDimension.chest};
    for (final dimension in [FitDimension.waist, FitDimension.hip]) {
      if (body[dimension] != null &&
          chart.sizes.any((r) => _values(r)[dimension] != null)) {
        required.add(dimension);
      }
    }
    final isBody = chart.basis == ChartBasis.body;
    final evaluations = <SizeEvaluation>[];
    for (final row in chart.sizes) {
      final values = _values(row);
      final comparisons = [
        for (final dimension in FitDimension.values)
          DimensionComparison(
            dimension: dimension,
            bodyCm: body[dimension],
            chartCm: values[dimension],
            usedForDecision: required.contains(dimension),
            status: _status(
              body[dimension],
              values[dimension],
              required.contains(dimension),
              chart,
              preference,
            ),
          ),
      ];
      final used = comparisons.where((c) => c.usedForDecision).toList();
      final statuses = used.map((c) => c.status).toSet();
      final verdict =
          statuses.contains(DimensionFitStatus.belowTarget) ||
              statuses.contains(DimensionFitStatus.aboveTarget)
          ? SizeFitVerdict.outsideTarget
          : statuses.contains(DimensionFitStatus.missing)
          ? SizeFitVerdict.insufficientData
          : statuses.contains(DimensionFitStatus.needsContext)
          ? SizeFitVerdict.needsContext
          : statuses.contains(DimensionFitStatus.partialTarget)
          ? SizeFitVerdict.partialTarget
          : SizeFitVerdict.meetsTarget;
      // Use the farthest endpoint, rather than assuming the midpoint is the actual garment.
      final distance = !isBody && verdict == SizeFitVerdict.meetsTarget
          ? used.fold<double>(0, (sum, c) {
                  final delta = c.differenceCm!;
                  return sum +
                      math.max(
                        (delta.min - preference.targetEaseCm).abs(),
                        (delta.max - preference.targetEaseCm).abs(),
                      );
                }) /
                used.length
          : null;
      evaluations.add(
        SizeEvaluation(
          label: row.label,
          comparisons: comparisons,
          verdict: verdict,
          distanceFromTargetCm: distance,
        ),
      );
    }
    final distances =
        evaluations
            .map((e) => e.distanceFromTargetCm)
            .whereType<double>()
            .toList()
          ..sort();
    final recommended = isBody
        ? evaluations
              .where((e) => e.verdict == SizeFitVerdict.meetsTarget)
              .map((e) => e.label)
              .toList()
        : distances.isEmpty
        ? <String>[]
        : evaluations
              .where(
                (e) =>
                    e.distanceFromTargetCm != null &&
                    (e.distanceFromTargetCm! - distances.first).abs() <=
                        _epsilon,
              )
              .map((e) => e.label)
              .toList();
    return SizeAnalysisResult(
      id: id,
      ruleVersion: ruleVersion,
      analyzedAt: analyzedAt ?? DateTime.now(),
      profile: profile,
      chart: chart,
      preference: preference,
      requiredDimensions: required.toList(),
      evaluations: evaluations,
      recommendedLabels: recommended,
      notes: [
        if (isBody) ...[
          'Profil dicocokkan langsung dengan rentang tubuh pada tabel, termasuk kedua batasnya. Tidak ada tambahan kelonggaran.',
          'Jika beberapa ukuran cocok, semuanya ditampilkan. Jika data antarbagian berbeda ukuran, tidak ada kandidat yang dipaksakan.',
          if (evaluations.any(
            (e) => e.comparisons.any(
              (c) =>
                  c.usedForDecision && c.chartCm != null && !c.chartCm!.isRange,
            ),
          ))
            'Angka tubuh tunggal belum menyatakan rentang yang diterima. Periksa panduan merek sebelum menentukan kecocokan.',
        ] else ...[
          'Selisih dihitung untuk kedua batas rentang. Kandidat harus memenuhi target pada seluruh rentang dan seluruh bagian yang dinilai.',
          'Pemeringkatan memakai rata-rata jarak batas terjauh dari titik tengah target. Hasil sebagian rentang tidak dianggap kandidat pasti.',
          if (chart.rangeMeaning == ChartRangeMeaning.stretch)
            'Batas regangan maksimum tidak menjamin kenyamanan. Rentang regangan belum digunakan untuk memastikan kandidat.',
          if (chart.rangeMeaning == ChartRangeMeaning.unknown)
            'Makna rentang belum diketahui; konfirmasi keterangannya sebelum menentukan kecocokan.',
          'Aturan kelonggaran ini merupakan aturan awal Usize, bukan standar semua merek. Potongan dan kenyamanan pribadi belum dinilai.',
        ],
        for (final dimension in [FitDimension.waist, FitDimension.hip])
          if (!required.contains(dimension))
            '${dimension.label} belum dinilai karena pasangan data profil dan tabel belum tersedia.',
        'Bahu ditampilkan sebagai informasi tambahan.',
      ],
    );
  }
}

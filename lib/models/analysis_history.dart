import 'dart:convert';

import 'body_measurement.dart';
import 'measurement_range.dart';
import 'reviewed_size_chart.dart';
import 'size_analysis_result.dart';

/// A saved result is read as it was calculated, without running newer fit rules.
/// Local image paths and authentication data are deliberately not persisted.
class AnalysisSnapshot {
  static const schemaVersion = 1;
  final String ruleVersion;
  final DateTime analyzedAt;
  final BodyMeasurement profile;
  final ChartBasis basis;
  final ChartUnit unit;
  final ChartRangeMeaning? rangeMeaning;
  final ChartMeasureType chestType;
  final ChartMeasureType? waistType, hipType;
  final FitPreference preference;
  final List<SizeChartDraftRow> inputRows;
  final List<FitDimension> requiredDimensions;
  final List<SizeEvaluation> evaluations;
  final List<String> recommendedLabels, notes;

  AnalysisSnapshot._({
    required this.ruleVersion,
    required this.analyzedAt,
    required this.profile,
    required this.basis,
    required this.unit,
    required this.rangeMeaning,
    required this.chestType,
    required this.waistType,
    required this.hipType,
    required this.preference,
    required List<SizeChartDraftRow> inputRows,
    required List<FitDimension> requiredDimensions,
    required List<SizeEvaluation> evaluations,
    required List<String> recommendedLabels,
    required List<String> notes,
  }) : inputRows = List.unmodifiable(inputRows),
       requiredDimensions = List.unmodifiable(requiredDimensions),
       evaluations = List.unmodifiable(evaluations),
       recommendedLabels = List.unmodifiable(recommendedLabels),
       notes = List.unmodifiable(notes);

  factory AnalysisSnapshot.fromResult(SizeAnalysisResult result) =>
      AnalysisSnapshot._(
        ruleVersion: result.ruleVersion,
        analyzedAt: result.analyzedAt,
        profile: result.profile,
        basis: result.chart.basis,
        unit: result.chart.unit,
        rangeMeaning: result.chart.rangeMeaning,
        chestType: result.chart.chestType,
        waistType: result.chart.waistType,
        hipType: result.chart.hipType,
        preference: result.preference,
        inputRows: result.chart.inputRows,
        requiredDimensions: result.requiredDimensions,
        evaluations: result.evaluations,
        recommendedLabels: result.recommendedLabels,
        notes: result.notes,
      );

  Map<String, dynamic> toJson() => {
    'schema_version': schemaVersion,
    'rule_version': ruleVersion,
    'analyzed_at': analyzedAt.toUtc().toIso8601String(),
    'profile': profile.toInsertJson(),
    'basis': basis.name,
    'unit': unit.name,
    'range_meaning': rangeMeaning?.name,
    'chest_type': chestType.name,
    'waist_type': waistType?.name,
    'hip_type': hipType?.name,
    'preference': preference.name,
    'input_rows': [
      for (final row in inputRows)
        {
          'label': row.label,
          'chest': row.chest,
          'waist': row.waist,
          'hip': row.hip,
          'shoulder': row.shoulder,
        },
    ],
    'required_dimensions': [for (final d in requiredDimensions) d.name],
    'evaluations': [
      for (final row in evaluations)
        {
          'label': row.label,
          'verdict': row.verdict.name,
          'distance': row.distanceFromTargetCm,
          'comparisons': [
            for (final c in row.comparisons)
              {
                'dimension': c.dimension.name,
                'body_cm': c.bodyCm,
                'chart_cm': c.chartCm == null
                    ? null
                    : {
                        'min': c.chartCm!.min,
                        'max': c.chartCm!.max,
                        'is_range': c.chartCm!.isRange,
                      },
                'used': c.usedForDecision,
                'status': c.status.name,
              },
          ],
        },
    ],
    'recommended_labels': recommendedLabels,
    'notes': notes,
  };

  factory AnalysisSnapshot.fromJson(Map<String, dynamic> json) {
    try {
      if (json['schema_version'] != schemaVersion) {
        throw const FormatException(
          'Versi riwayat belum didukung aplikasi ini.',
        );
      }
      final p = _map(json['profile']);
      final rows = (json['input_rows'] as List).map((value) {
        final row = _map(value);
        return SizeChartDraftRow(
          label: row['label'] as String,
          chest: row['chest'] as String,
          waist: row['waist'] as String,
          hip: row['hip'] as String,
          shoulder: row['shoulder'] as String,
        );
      }).toList();
      final evaluations = (json['evaluations'] as List).map((value) {
        final row = _map(value);
        return SizeEvaluation(
          label: row['label'] as String,
          verdict: SizeFitVerdict.values.byName(row['verdict'] as String),
          distanceFromTargetCm: _number(row['distance']),
          comparisons: (row['comparisons'] as List).map((value) {
            final c = _map(value);
            final rawRange = c['chart_cm'];
            MeasurementRange? range;
            if (rawRange != null) {
              final r = _map(rawRange);
              final min = _number(r['min'])!;
              final max = _number(r['max'])!;
              final isRange = r['is_range'] as bool;
              if (min <= 0 || max < min || (!isRange && min != max)) {
                throw const FormatException('Rentang tersimpan tidak valid.');
              }
              range = isRange
                  ? MeasurementRange.interval(min, max)
                  : MeasurementRange.single(min);
            }
            return DimensionComparison(
              dimension: FitDimension.values.byName(c['dimension'] as String),
              bodyCm: _number(c['body_cm']),
              chartCm: range,
              usedForDecision: c['used'] as bool,
              status: DimensionFitStatus.values.byName(c['status'] as String),
            );
          }).toList(),
        );
      }).toList();
      if (rows.isEmpty || evaluations.isEmpty) {
        throw const FormatException('Tabel riwayat kosong.');
      }
      return AnalysisSnapshot._(
        ruleVersion: json['rule_version'] as String,
        analyzedAt: DateTime.parse(json['analyzed_at'] as String),
        profile: BodyMeasurement(
          id: p['id'] as String,
          label: p['label'] as String,
          chestCm: _number(p['chest_cm'])!,
          waistCm: _number(p['waist_cm']),
          hipCm: _number(p['hip_cm']),
          shoulderWidthCm: _number(p['shoulder_width_cm']),
          heightCm: _number(p['height_cm']),
          weightKg: _number(p['weight_kg']),
          measuredAt: DateTime.parse(p['measured_at'] as String),
        ),
        basis: ChartBasis.values.byName(json['basis'] as String),
        unit: ChartUnit.values.byName(json['unit'] as String),
        rangeMeaning: json['range_meaning'] == null
            ? null
            : ChartRangeMeaning.values.byName(json['range_meaning'] as String),
        chestType: ChartMeasureType.values.byName(json['chest_type'] as String),
        waistType: json['waist_type'] == null
            ? null
            : ChartMeasureType.values.byName(json['waist_type'] as String),
        hipType: json['hip_type'] == null
            ? null
            : ChartMeasureType.values.byName(json['hip_type'] as String),
        preference: FitPreference.values.byName(json['preference'] as String),
        inputRows: rows,
        requiredDimensions: (json['required_dimensions'] as List)
            .map((d) => FitDimension.values.byName(d as String))
            .toList(),
        evaluations: evaluations,
        recommendedLabels: List<String>.from(
          json['recommended_labels'] as List,
        ),
        notes: List<String>.from(json['notes'] as List),
      );
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Format detail riwayat tidak dapat dibaca.');
    }
  }

  static Map<String, dynamic> _map(dynamic value) =>
      Map<String, dynamic>.from(value as Map);
  static double? _number(dynamic value) {
    if (value == null) return null;
    final number = (value as num).toDouble();
    if (!number.isFinite) {
      throw const FormatException('Angka riwayat tidak valid.');
    }
    return number;
  }
}

class AnalysisHistoryDraft {
  final String id, title;
  final AnalysisSnapshot snapshot;
  AnalysisHistoryDraft({
    required this.id,
    required String title,
    required this.snapshot,
  }) : title = title.trim() {
    final error = titleError(title);
    if (error != null) throw FormatException(error);
  }
  static String? titleError(String? value) {
    final title = value?.trim() ?? '';
    if (title.isEmpty) return 'Nama produk atau analisis wajib diisi.';
    if (title.runes.length > 80) return 'Maksimal 80 karakter.';
    return null;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'payload': snapshot.toJson(),
  };
  bool matches(AnalysisHistoryEntry entry) =>
      id == entry.id &&
      title == entry.title &&
      jsonEncode(snapshot.toJson()) == jsonEncode(entry.snapshot.toJson());
}

class AnalysisHistoryEntry {
  final String id, title;
  final DateTime createdAt;
  final AnalysisSnapshot snapshot;
  const AnalysisHistoryEntry({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.snapshot,
  });
  factory AnalysisHistoryEntry.fromJson(Map<String, dynamic> json) =>
      AnalysisHistoryEntry(
        id: json['id'] as String,
        title: json['title'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        snapshot: AnalysisSnapshot.fromJson(
          Map<String, dynamic>.from(json['payload'] as Map),
        ),
      );
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'created_at': createdAt.toUtc().toIso8601String(),
    'payload': snapshot.toJson(),
  };
  AnalysisHistorySummary get summary => AnalysisHistorySummary(
    id: id,
    title: title,
    createdAt: createdAt,
    profileLabel: snapshot.profile.label,
    basis: snapshot.basis,
    recommendedLabels: snapshot.recommendedLabels,
  );
}

class AnalysisHistorySummary {
  final String id, title, profileLabel;
  final DateTime createdAt;
  final ChartBasis basis;
  final List<String> recommendedLabels;
  AnalysisHistorySummary({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.profileLabel,
    required this.basis,
    required List<String> recommendedLabels,
  }) : recommendedLabels = List.unmodifiable(recommendedLabels);
  factory AnalysisHistorySummary.fromJson(Map<String, dynamic> json) =>
      AnalysisHistorySummary(
        id: json['id'] as String,
        title: json['title'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        profileLabel: json['profile_label'] as String,
        basis: ChartBasis.values.byName(json['chart_basis'] as String),
        recommendedLabels: List<String>.from(
          json['recommended_labels'] as List,
        ),
      );
  String get recommendation => recommendedLabels.isEmpty
      ? 'Belum ada kandidat yang memenuhi target'
      : 'Kandidat: ${recommendedLabels.join(', ')}';
}

class AnalysisHistoryCursor {
  final DateTime createdAt;
  final String id;
  const AnalysisHistoryCursor(this.createdAt, this.id);
}

class AnalysisHistoryPage {
  final List<AnalysisHistorySummary> items;
  final AnalysisHistoryCursor? nextCursor;
  AnalysisHistoryPage(List<AnalysisHistorySummary> items, this.nextCursor)
    : items = List.unmodifiable(items);
}

class AnalysisHistoryConflict implements Exception {
  const AnalysisHistoryConflict();
}

class AnalysisHistoryUnavailable implements Exception {
  const AnalysisHistoryUnavailable();
}

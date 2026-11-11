import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:usize/models/analysis_history.dart';
import 'package:usize/models/reviewed_size_chart.dart';
import 'history_fixtures.dart';

void main() {
  for (final garment in [false, true]) {
    test(
      'snapshot survives JSON with both range endpoints; garment=$garment',
      () {
        final original = AnalysisSnapshot.fromResult(
          historyResult(garment: garment),
        );
        final restored = AnalysisSnapshot.fromJson(
          jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
        );
        expect(restored.toJson(), original.toJson());
        expect(
          restored.evaluations.first.comparisons.first.chartCm!.min,
          garment ? 100 : 92,
        );
        expect(
          restored.evaluations.first.comparisons.first.chartCm!.max,
          garment ? 104 : 97,
        );
        expect(
          restored.evaluations.first.comparisons.first.chartCm!.isRange,
          isTrue,
        );
        expect(
          restored.evaluations.first.comparisons.last.chartCm!.isRange,
          isFalse,
        );
        expect(restored.evaluations.last.comparisons.last.chartCm, isNull);
        expect(
          restored.inputRows.first.chest,
          garment ? '100 - 104' : '92 - 97',
        );
        expect(restored.profile.userId, isNull);
        expect(restored.basis, garment ? ChartBasis.garment : ChartBasis.body);
      },
    );
  }
  test(
    'historical verdict and rule version are never recomputed from current rules',
    () {
      final json = AnalysisSnapshot.fromResult(historyResult()).toJson();
      json['rule_version'] = 'archived-rule-version';
      json['recommended_labels'] = ['L'];
      json['notes'] = ['Catatan versi lama'];
      final restored = AnalysisSnapshot.fromJson(json);
      expect(restored.recommendedLabels, ['L']);
      expect(restored.ruleVersion, 'archived-rule-version');
      expect(restored.notes, ['Catatan versi lama']);
    },
  );
  test(
    'snapshot excludes temporary image paths and raw OCR, preserves old body values',
    () {
      final snapshot = AnalysisSnapshot.fromResult(historyResult());
      final encoded = jsonEncode(snapshot.toJson());
      expect(encoded.contains('/local/temporary.png'), isFalse);
      expect(encoded.contains('private raw source'), isFalse);
      final changedProfile = historyProfile(chest: 110, label: 'Diubah');
      expect(changedProfile.chestCm, 110);
      expect(snapshot.profile.chestCm, 94);
      expect(
        () => snapshot.recommendedLabels.add('XL'),
        throwsUnsupportedError,
      );
    },
  );
  test('unsupported or damaged saved data produces explicit errors', () {
    final json = AnalysisSnapshot.fromResult(historyResult()).toJson();
    expect(
      () => AnalysisSnapshot.fromJson({...json, 'schema_version': 99}),
      throwsFormatException,
    );
    expect(
      () => AnalysisSnapshot.fromJson({...json, 'profile': null}),
      throwsFormatException,
    );
    expect(
      () => AnalysisSnapshot.fromJson({...json, 'evaluations': []}),
      throwsFormatException,
    );
  });
  test('product names are required and bounded', () {
    expect(AnalysisHistoryDraft.titleError(' '), isNotNull);
    expect(AnalysisHistoryDraft.titleError('a' * 81), isNotNull);
    expect(historyDraft(title: '  Kemeja A  ').title, 'Kemeja A');
  });
}

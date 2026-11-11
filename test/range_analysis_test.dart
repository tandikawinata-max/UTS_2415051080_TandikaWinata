import 'package:flutter_test/flutter_test.dart';
import 'package:usize/models/body_measurement.dart';
import 'package:usize/models/reviewed_size_chart.dart';
import 'package:usize/models/size_analysis_result.dart';
import 'package:usize/services/size_analysis_service.dart';

ReviewedSizeChart makeChart(
  List<SizeChartDraftRow> rows, {
  ChartBasis basis = ChartBasis.body,
  ChartRangeMeaning? meaning,
}) => ReviewedSizeChart.confirm(
  sourceImagePath: '/x.png',
  sourceOcrText: '',
  unit: ChartUnit.cm,
  basis: basis,
  rangeMeaning: meaning,
  chestType: ChartMeasureType.circumference,
  waistType: ChartMeasureType.circumference,
  hipType: ChartMeasureType.circumference,
  rows: rows,
);
SizeAnalysisResult run(
  ReviewedSizeChart chart, {
  double chest = 94,
  double? waist = 80,
  FitPreference preference = FitPreference.regular,
}) => const SizeAnalysisService().analyze(
  id: 'test',
  profile: BodyMeasurement(
    id: 'a',
    label: 'A',
    chestCm: chest,
    waistCm: waist,
    measuredAt: DateTime(2026, 11, 10),
  ),
  chart: chart,
  preference: preference,
);

void main() {
  final bodyChart = makeChart(const [
    SizeChartDraftRow(label: 'M', chest: '92-97', waist: '78-83'),
    SizeChartDraftRow(label: 'L', chest: '98-104', waist: '84-90'),
    SizeChartDraftRow(label: 'XL', chest: '105-111', waist: '91-97'),
  ]);
  test(
    'screenshot example selects M directly without ease or midpoint ranking',
    () {
      for (final fit in FitPreference.values) {
        final result = run(bodyChart, preference: fit);
        expect(result.recommendedLabels, ['M']);
        expect(result.evaluations.first.distanceFromTargetCm, isNull);
      }
    },
  );
  test('body range endpoints inclusive, no arbitrary rounding across gaps', () {
    expect(run(bodyChart, chest: 92, waist: 78).recommendedLabels, ['M']);
    expect(run(bodyChart, chest: 97, waist: 83).recommendedLabels, ['M']);
    expect(run(bodyChart, chest: 97.5, waist: 83.5).recommendedLabels, isEmpty);
  });
  test('conflicting body dimensions produce no forced candidate', () {
    expect(run(bodyChart, chest: 94, waist: 86).recommendedLabels, isEmpty);
  });
  test('overlapping body ranges preserve all matching sizes', () {
    final result = run(
      makeChart(const [
        SizeChartDraftRow(label: 'M', chest: '92-98'),
        SizeChartDraftRow(label: 'L', chest: '98-104'),
      ]),
      chest: 98,
    );
    expect(result.recommendedLabels, ['M', 'L']);
  });
  test(
    'missing required values and nominal body numbers do not become recommendations',
    () {
      final result = run(
        makeChart(const [
          SizeChartDraftRow(label: 'M', chest: '92-97'),
          SizeChartDraftRow(label: 'L', chest: '94', waist: '78-83'),
        ]),
      );
      expect(result.evaluations.first.verdict, SizeFitVerdict.insufficientData);
      expect(result.evaluations.last.verdict, SizeFitVerdict.needsContext);
      expect(result.recommendedLabels, isEmpty);
    },
  );
  test(
    'garment ranges distinguish complete, partial, below and above target',
    () {
      final result = run(
        makeChart(
          const [
            SizeChartDraftRow(label: 'A', chest: '100-104'),
            SizeChartDraftRow(label: 'B', chest: '96-104'),
            SizeChartDraftRow(label: 'C', chest: '92-97'),
            SizeChartDraftRow(label: 'D', chest: '105-111'),
          ],
          basis: ChartBasis.garment,
          meaning: ChartRangeMeaning.variation,
        ),
      );
      expect(result.recommendedLabels, ['A']);
      expect(result.evaluations.map((e) => e.verdict), [
        SizeFitVerdict.meetsTarget,
        SizeFitVerdict.partialTarget,
        SizeFitVerdict.outsideTarget,
        SizeFitVerdict.outsideTarget,
      ]);
      expect(result.evaluations.first.comparisons.first.differenceCm!.min, 6);
      expect(result.evaluations.first.comparisons.first.differenceCm!.max, 10);
      expect(result.evaluations.first.distanceFromTargetCm, 3);
    },
  );
  test(
    'ranking uses farthest endpoint and never averages away uncertainty',
    () {
      final result = run(
        makeChart(
          const [
            SizeChartDraftRow(label: 'A', chest: '98-104'),
            SizeChartDraftRow(label: 'B', chest: '100-102'),
          ],
          basis: ChartBasis.garment,
          meaning: ChartRangeMeaning.variation,
        ),
      );
      expect(result.recommendedLabels, ['B']);
    },
  );
  test(
    'stretch and unknown ranges stay informational, not positive fit claims',
    () {
      for (final meaning in [
        ChartRangeMeaning.stretch,
        ChartRangeMeaning.unknown,
      ]) {
        final result = run(
          makeChart(
            const [SizeChartDraftRow(label: 'M', chest: '100-104')],
            basis: ChartBasis.garment,
            meaning: meaning,
          ),
        );
        expect(result.recommendedLabels, isEmpty);
        expect(result.evaluations.single.verdict, SizeFitVerdict.needsContext);
      }
    },
  );
}

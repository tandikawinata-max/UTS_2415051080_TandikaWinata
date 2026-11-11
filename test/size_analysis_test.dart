import 'package:flutter_test/flutter_test.dart';
import 'package:usize/models/body_measurement.dart';
import 'package:usize/models/reviewed_size_chart.dart';
import 'package:usize/models/size_analysis_result.dart';
import 'package:usize/providers/measurement_provider.dart';
import 'package:usize/providers/screenshot_provider.dart';
import 'package:usize/providers/size_analysis_provider.dart';
import 'package:usize/repositories/demo_measurement_repository.dart';
import 'package:usize/repositories/screenshot_repository.dart';
import 'package:usize/services/size_analysis_service.dart';

BodyMeasurement profile({
  String id = 'a',
  double chest = 94,
  double? waist = 80,
  double? hip,
}) => BodyMeasurement(
  id: id,
  label: 'Profil $id',
  chestCm: chest,
  waistCm: waist,
  hipCm: hip,
  shoulderWidthCm: 40,
  measuredAt: DateTime(2026, 11, 10),
);
ReviewedSizeChart chart(List<SizeChartDraftRow> rows) =>
    ReviewedSizeChart.confirm(
      sourceImagePath: '/chart.png',
      sourceOcrText: 'test',
      unit: ChartUnit.cm,
      basis: ChartBasis.garment,
      chestType: ChartMeasureType.circumference,
      waistType: ChartMeasureType.circumference,
      hipType: ChartMeasureType.circumference,
      rows: rows,
    );
final example = chart(const [
  SizeChartDraftRow(label: 'S', chest: '92', waist: '76', shoulder: '38'),
  SizeChartDraftRow(label: 'M', chest: '100', waist: '86', shoulder: '40'),
  SizeChartDraftRow(label: 'L', chest: '104', waist: '90', shoulder: '42'),
]);

class Repository implements ScreenshotRepository {
  String? picked = '/chart.png';
  @override
  Future<String?> pickScreenshot() async => picked;
  @override
  Future<String?> recoverScreenshot() async => null;
  @override
  Future<String> readText(String path) async => 'test';
}

void main() {
  const service = SizeAnalysisService();
  SizeAnalysisResult run(
    ReviewedSizeChart c, {
    BodyMeasurement? body,
    FitPreference fit = FitPreference.regular,
  }) => service.analyze(
    id: 'test',
    profile: body ?? profile(),
    chart: c,
    preference: fit,
  );
  test('M wins with correct differences and target distance', () {
    final result = run(example);
    expect(result.recommendedLabels, ['M']);
    expect(result.requiredDimensions, [FitDimension.chest, FitDimension.waist]);
    expect(result.evaluations[1].comparisons[0].differenceCm!.min, 6);
    expect(result.evaluations[1].distanceFromTargetCm, 1);
    expect(result.evaluations[0].verdict, SizeFitVerdict.outsideTarget);
  });
  test('no forced recommendation', () {
    final result = run(
      chart(const [
        SizeChartDraftRow(label: 'S', chest: '90'),
        SizeChartDraftRow(label: 'XL', chest: '120'),
      ]),
    );
    expect(result.recommendedLabels, isEmpty);
  });
  test('inclusive boundaries and equal distances preserve ties', () {
    final result = run(
      chart(const [
        SizeChartDraftRow(label: 'A', chest: '98'),
        SizeChartDraftRow(label: 'B', chest: '104'),
      ]),
    );
    expect(result.recommendedLabels, ['A', 'B']);
  });
  test('missing required value cannot beat complete data', () {
    final result = run(
      chart(const [
        SizeChartDraftRow(label: 'M', chest: '101'),
        SizeChartDraftRow(label: 'L', chest: '102', waist: '88'),
      ]),
    );
    expect(result.evaluations.first.verdict, SizeFitVerdict.insufficientData);
    expect(result.evaluations.first.distanceFromTargetCm, isNull);
    expect(result.recommendedLabels, ['L']);
  });
  test('all required dimensions participate, including hip', () {
    final result = run(
      chart(const [
        SizeChartDraftRow(label: 'M', chest: '101', hip: '95'),
        SizeChartDraftRow(label: 'L', chest: '102', hip: '103'),
      ]),
      body: profile(hip: 96),
    );
    expect(result.requiredDimensions, [FitDimension.chest, FitDimension.hip]);
    expect(result.recommendedLabels, ['L']);
  });
  test('missing values stay null and shoulders are informational', () {
    final result = run(example, body: profile(waist: null));
    expect(result.requiredDimensions, [FitDimension.chest]);
    expect(result.evaluations.first.comparisons[1].differenceCm, isNull);
    expect(
      result.evaluations.first.comparisons[3].status,
      DimensionFitStatus.informational,
    );
  });
  test('all preferences apply their own boundaries', () {
    final c = chart(const [
      SizeChartDraftRow(label: 'A', chest: '97'),
      SizeChartDraftRow(label: 'B', chest: '101'),
      SizeChartDraftRow(label: 'C', chest: '108'),
    ]);
    expect(run(c, fit: FitPreference.closeFit).recommendedLabels, ['A']);
    expect(run(c).recommendedLabels, ['B']);
    expect(run(c, fit: FitPreference.relaxed).recommendedLabels, ['C']);
  });
  test('non-finite or non-positive values rejected', () {
    for (final value in [double.nan, double.infinity, 0.0, -1.0]) {
      expect(
        () => run(example, body: profile(chest: value)),
        throwsFormatException,
      );
    }
  });
  group('source lifecycle', () {
    late MeasurementProvider measurements;
    late ScreenshotProvider screenshots;
    late SizeAnalysisProvider analysis;
    late Repository repository;
    setUp(() async {
      measurements = MeasurementProvider(
        DemoMeasurementRepository(
          initialMeasurements: [
            profile(),
            profile(id: 'b', chest: 110),
          ],
        ),
      );
      await measurements.loadMeasurements();
      measurements.selectMeasurement('a');
      repository = Repository();
      screenshots = ScreenshotProvider(repository);
      await screenshots.pickScreenshot();
      screenshots.confirmChart(example, expectedRevision: screenshots.revision);
      analysis = SizeAnalysisProvider(
        measurements: measurements,
        screenshots: screenshots,
      );
    });
    tearDown(() {
      analysis.dispose();
      screenshots.dispose();
      measurements.dispose();
    });
    test('profile selection, edits and deletion clear result', () async {
      expect(analysis.analyze(), isTrue);
      measurements.selectMeasurement('b');
      expect(analysis.result, isNull);
      analysis.analyze();
      await measurements.updateMeasurement(profile(id: 'b', chest: 100));
      expect(analysis.result, isNull);
      analysis.analyze();
      await measurements.deleteMeasurement('b');
      expect(analysis.result, isNull);
      expect(analysis.canAnalyze, isFalse);
    });
    test('preference, OCR retry, and new chart invalidate results', () async {
      analysis.analyze();
      analysis.setPreference(FitPreference.relaxed);
      expect(analysis.result, isNull);
      analysis.analyze();
      await screenshots.readAgain();
      expect(analysis.result, isNull);
      expect(analysis.canAnalyze, isFalse);
      screenshots.confirmChart(example, expectedRevision: screenshots.revision);
      expect(analysis.analyze(), isTrue);
      screenshots.confirmChart(
        chart(const [SizeChartDraftRow(label: 'X', chest: '105')]),
        expectedRevision: screenshots.revision,
      );
      expect(analysis.result, isNull);
    });
    test(
      'cancelled gallery preserves results; new image clears them',
      () async {
        analysis.analyze();
        final previous = analysis.result;
        repository.picked = null;
        await screenshots.pickScreenshot();
        expect(analysis.result, same(previous));
        repository.picked = '/other.png';
        await screenshots.pickScreenshot();
        expect(analysis.result, isNull);
        expect(analysis.canAnalyze, isFalse);
      },
    );
  });
}

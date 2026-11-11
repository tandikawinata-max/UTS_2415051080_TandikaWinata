import 'dart:async';
import 'package:usize/models/analysis_history.dart';
import 'package:usize/models/body_measurement.dart';
import 'package:usize/models/reviewed_size_chart.dart';
import 'package:usize/models/size_analysis_result.dart';
import 'package:usize/repositories/demo_analysis_history_repository.dart';
import 'package:usize/repositories/screenshot_repository.dart';
import 'package:usize/services/size_analysis_service.dart';

const historyResultId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
BodyMeasurement historyProfile({
  double chest = 94,
  String label = 'Profil A',
}) => BodyMeasurement(
  id: 'profile-a',
  label: label,
  chestCm: chest,
  waistCm: 80,
  measuredAt: DateTime.utc(2026, 11, 10),
);
SizeAnalysisResult historyResult({
  String id = historyResultId,
  bool garment = false,
}) => const SizeAnalysisService().analyze(
  id: id,
  profile: historyProfile(),
  preference: FitPreference.regular,
  analyzedAt: DateTime.utc(2026, 11, 10, 12),
  chart: ReviewedSizeChart.confirm(
    sourceImagePath: '/local/temporary.png',
    sourceOcrText: 'private raw source',
    unit: ChartUnit.cm,
    basis: garment ? ChartBasis.garment : ChartBasis.body,
    rangeMeaning: garment ? ChartRangeMeaning.variation : null,
    chestType: ChartMeasureType.circumference,
    waistType: ChartMeasureType.circumference,
    rows: [
      SizeChartDraftRow(
        label: 'M',
        chest: garment ? '100 - 104' : '92 - 97',
        waist: garment ? '86 - 90' : '78 - 83',
        shoulder: '40',
      ),
      const SizeChartDraftRow(label: 'L', chest: '105-111', waist: '91-97'),
    ],
  ),
);
AnalysisHistoryDraft historyDraft({
  String id = historyResultId,
  String title = 'Kemeja linen',
}) => AnalysisHistoryDraft(
  id: id,
  title: title,
  snapshot: AnalysisSnapshot.fromResult(historyResult(id: id)),
);

class ControlledHistoryRepository extends DemoAnalysisHistoryRepository {
  ControlledHistoryRepository({super.pageSize});
  bool failLoad = false,
      failDetail = false,
      loseSaveReply = false,
      failDelete = false,
      loseDeleteReply = false;
  int saveCalls = 0;
  Completer<void>? saveGate;
  @override
  Future<AnalysisHistoryPage> fetchPage({AnalysisHistoryCursor? after}) async {
    if (failLoad) throw StateError('offline');
    return super.fetchPage(after: after);
  }

  @override
  Future<AnalysisHistoryEntry?> findById(String id) async {
    if (failDetail) throw StateError('offline');
    return super.findById(id);
  }

  @override
  Future<AnalysisHistoryEntry> save(AnalysisHistoryDraft draft) async {
    saveCalls++;
    if (saveGate != null) await saveGate!.future;
    final saved = await super.save(draft);
    if (loseSaveReply) {
      loseSaveReply = false;
      throw TimeoutException('Saved on server, reply lost');
    }
    return saved;
  }

  @override
  Future<void> delete(String id) async {
    if (failDelete) throw StateError('offline');
    await super.delete(id);
    if (loseDeleteReply) {
      loseDeleteReply = false;
      throw TimeoutException('Deleted on server, reply lost');
    }
  }
}

class HistoryScreenshotRepository implements ScreenshotRepository {
  @override
  Future<String?> pickScreenshot() async => '/local/temporary.png';
  @override
  Future<String?> recoverScreenshot() async => null;
  @override
  Future<String> readText(String path) async =>
      'BODY MEASUREMENTS cm\nSIZE DADA PINGGANG\nM 92 - 97 78 - 83\nL 98 - 104 84 - 90';
}

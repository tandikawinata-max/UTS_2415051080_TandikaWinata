import '../models/analysis_history.dart';

abstract class AnalysisHistoryRepository {
  Future<AnalysisHistoryPage> fetchPage({AnalysisHistoryCursor? after});
  Future<AnalysisHistoryEntry?> findById(String id);
  Future<AnalysisHistoryEntry> save(AnalysisHistoryDraft draft);
  Future<void> delete(String id);
}

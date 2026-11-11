import '../models/analysis_history.dart';
import '../services/analysis_history_service.dart';
import 'analysis_history_repository.dart';

class SupabaseAnalysisHistoryRepository implements AnalysisHistoryRepository {
  final AnalysisHistoryService _service;
  SupabaseAnalysisHistoryRepository(this._service);
  @override
  Future<AnalysisHistoryPage> fetchPage({AnalysisHistoryCursor? after}) async {
    final rows = await _service.fetchPage(after: after);
    final items = rows
        .take(AnalysisHistoryService.pageSize)
        .map(AnalysisHistorySummary.fromJson)
        .toList();
    return AnalysisHistoryPage(
      items,
      rows.length > AnalysisHistoryService.pageSize
          ? AnalysisHistoryCursor(items.last.createdAt, items.last.id)
          : null,
    );
  }

  @override
  Future<AnalysisHistoryEntry?> findById(String id) async {
    final row = await _service.findById(id);
    return row == null ? null : AnalysisHistoryEntry.fromJson(row);
  }

  @override
  Future<AnalysisHistoryEntry> save(AnalysisHistoryDraft draft) async =>
      AnalysisHistoryEntry.fromJson(await _service.save(draft));
  @override
  Future<void> delete(String id) => _service.delete(id);
}

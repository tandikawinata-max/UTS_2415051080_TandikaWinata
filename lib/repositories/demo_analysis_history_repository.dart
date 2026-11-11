import 'dart:convert';
import '../models/analysis_history.dart';
import 'analysis_history_repository.dart';

/// In-memory fixture for explicitly injected demo/test mode, never account storage.
class DemoAnalysisHistoryRepository implements AnalysisHistoryRepository {
  final Map<String, Map<String, dynamic>> _rows = {};
  final int pageSize;
  DemoAnalysisHistoryRepository({this.pageSize = 20});
  @override
  Future<AnalysisHistoryEntry> save(AnalysisHistoryDraft draft) async {
    final existing = await findById(draft.id);
    if (existing != null) {
      if (!draft.matches(existing)) throw const AnalysisHistoryConflict();
      return existing;
    }
    _rows[draft.id] =
        jsonDecode(
              jsonEncode({
                ...draft.toJson(),
                'created_at': DateTime.now().toUtc().toIso8601String(),
              }),
            )
            as Map<String, dynamic>;
    return (await findById(draft.id))!;
  }

  @override
  Future<AnalysisHistoryEntry?> findById(String id) async =>
      _rows[id] == null ? null : AnalysisHistoryEntry.fromJson(_rows[id]!);
  @override
  Future<AnalysisHistoryPage> fetchPage({AnalysisHistoryCursor? after}) async {
    final items =
        _rows.values
            .map(AnalysisHistoryEntry.fromJson)
            .map((e) => e.summary)
            .where(
              (e) =>
                  after == null ||
                  e.createdAt.isBefore(after.createdAt) ||
                  (e.createdAt.isAtSameMomentAs(after.createdAt) &&
                      e.id.compareTo(after.id) < 0),
            )
            .toList()
          ..sort((a, b) {
            final date = b.createdAt.compareTo(a.createdAt);
            return date == 0 ? b.id.compareTo(a.id) : date;
          });
    final page = items.take(pageSize).toList();
    return AnalysisHistoryPage(
      page,
      items.length > pageSize
          ? AnalysisHistoryCursor(page.last.createdAt, page.last.id)
          : null,
    );
  }

  @override
  Future<void> delete(String id) async {
    _rows.remove(id);
  }
}

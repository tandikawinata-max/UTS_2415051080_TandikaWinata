import 'package:flutter/foundation.dart';
import '../models/analysis_history.dart';
import '../repositories/analysis_history_repository.dart';

class AnalysisHistoryProvider extends ChangeNotifier {
  final AnalysisHistoryRepository _repository;
  AnalysisHistoryProvider(this._repository);
  List<AnalysisHistorySummary> _items = const [];
  final _saved = <String, AnalysisHistoryEntry>{};
  final _pending = <String, AnalysisHistoryDraft>{};
  AnalysisHistoryCursor? _cursor;
  bool _disposed = false;
  bool isLoading = false,
      isSaving = false,
      isDeleting = false,
      hasLoaded = false;
  String? loadError, saveError, deleteError, saveErrorId, deleteErrorId;
  List<AnalysisHistorySummary> get items => _items;
  bool get hasMore => _cursor != null;
  bool get isBusy => isLoading || isSaving || isDeleting;
  AnalysisHistoryEntry? savedFor(String id) => _saved[id];
  AnalysisHistoryDraft? pendingFor(String id) => _pending[id];

  Future<void> loadHistory({bool more = false}) async {
    if (_disposed || isBusy || (more && !hasMore)) return;
    isLoading = true;
    loadError = null;
    notifyListeners();
    try {
      final page = await _repository.fetchPage(after: more ? _cursor : null);
      if (_disposed) return;
      final byId = {
        if (more)
          for (final e in _items) e.id: e,
        for (final e in page.items) e.id: e,
      };
      _items = List.unmodifiable(byId.values);
      _cursor = page.nextCursor;
      if (!more && page.nextCursor == null) {
        _saved.removeWhere((id, _) => !byId.containsKey(id));
      }
      hasLoaded = true;
    } catch (_) {
      if (!_disposed) {
        loadError =
            'Riwayat belum dapat dimuat. Periksa koneksi, lalu coba lagi.';
      }
    } finally {
      if (!_disposed) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<AnalysisHistoryEntry?> save(AnalysisHistoryDraft draft) async {
    if (_disposed || isBusy) return null;
    final saved = _saved[draft.id];
    if (saved != null) return saved;
    final request = _pending.putIfAbsent(draft.id, () => draft);
    isSaving = true;
    saveError = null;
    saveErrorId = draft.id;
    notifyListeners();
    try {
      final entry = await _repository.save(request);
      if (_disposed) return null;
      _saved[entry.id] = entry;
      _pending.remove(entry.id);
      final updated = [entry.summary, ..._items.where((e) => e.id != entry.id)]
        ..sort((a, b) {
          final date = b.createdAt.compareTo(a.createdAt);
          return date == 0 ? b.id.compareTo(a.id) : date;
        });
      _items = List.unmodifiable(updated);
      // Preserve the previous page boundary when adding a new result.
      return entry;
    } on AnalysisHistoryConflict {
      if (!_disposed) {
        saveError =
            'Hasil dengan ID ini sudah tersimpan berbeda. Periksa riwayat sebelum mencoba lagi.';
      }
      return null;
    } on AnalysisHistoryUnavailable {
      if (!_disposed) {
        saveError = 'Sesi akun berubah. Masuk kembali untuk menyimpan hasil.';
      }
      return null;
    } catch (_) {
      if (!_disposed) {
        saveError =
            'Penyimpanan belum terkonfirmasi. Coba simpan lagi; nama dan hasil tetap dipertahankan agar tidak tersimpan ganda.';
      }
      return null;
    } finally {
      if (!_disposed) {
        isSaving = false;
        notifyListeners();
      }
    }
  }

  Future<AnalysisHistoryEntry?> loadDetail(String id) async {
    if (_disposed) throw const AnalysisHistoryUnavailable();
    final result = await _repository.findById(id);
    if (_disposed) throw const AnalysisHistoryUnavailable();
    return result;
  }

  Future<bool> delete(String id) async {
    if (_disposed || isBusy) return false;
    isDeleting = true;
    deleteError = null;
    deleteErrorId = id;
    notifyListeners();
    try {
      await _repository.delete(id);
      if (_disposed) return false;
      _items = List.unmodifiable(_items.where((e) => e.id != id));
      _saved.remove(id);
      _pending.remove(id);
      return true;
    } catch (_) {
      if (!_disposed) {
        deleteError =
            'Penghapusan belum terkonfirmasi. Coba hapus lagi atau muat ulang riwayat.';
      }
      return false;
    } finally {
      if (!_disposed) {
        isDeleting = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _items = const [];
    _saved.clear();
    _pending.clear();
    super.dispose();
  }
}

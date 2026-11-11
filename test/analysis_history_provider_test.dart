import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:usize/providers/analysis_history_provider.dart';
import 'history_fixtures.dart';

void main() {
  test('complete refresh clears saved status after remote deletion', () async {
    final repo = ControlledHistoryRepository();
    final state = AnalysisHistoryProvider(repo);
    addTearDown(state.dispose);
    await state.save(historyDraft());
    await repo.delete(historyResultId);
    await state.loadHistory();
    expect(state.items, isEmpty);
    expect(state.savedFor(historyResultId), isNull);
  });
  test('lost save response retries exact draft with one stored row', () async {
    final repo = ControlledHistoryRepository()..loseSaveReply = true;
    final state = AnalysisHistoryProvider(repo);
    addTearDown(state.dispose);
    expect(await state.save(historyDraft()), isNull);
    expect(state.pendingFor(historyResultId)?.title, 'Kemeja linen');
    expect(state.saveError, isNotNull);
    final saved = await state.save(
      historyDraft(title: 'Nama diubah saat retry'),
    );
    expect(saved?.title, 'Kemeja linen');
    expect((await repo.fetchPage()).items, hasLength(1));
    expect(state.saveError, isNull);
    expect(state.pendingFor(historyResultId), isNull);
  });
  test(
    'concurrent save and repeated clicks never issue duplicate writes',
    () async {
      final repo = ControlledHistoryRepository()..saveGate = Completer<void>();
      final state = AnalysisHistoryProvider(repo);
      addTearDown(state.dispose);
      final first = state.save(historyDraft());
      expect(await state.save(historyDraft()), isNull);
      expect(repo.saveCalls, 1);
      repo.saveGate!.complete();
      expect(await first, isNotNull);
      expect(await state.save(historyDraft()), isNotNull);
      expect(repo.saveCalls, 1);
    },
  );
  test(
    'conflicting ID preserves existing record instead of overwriting',
    () async {
      final repo = ControlledHistoryRepository();
      await repo.save(historyDraft(title: 'Asli'));
      final state = AnalysisHistoryProvider(repo);
      addTearDown(state.dispose);
      expect(await state.save(historyDraft(title: 'Berbeda')), isNull);
      expect(state.saveError, contains('sudah tersimpan berbeda'));
      expect((await repo.findById(historyResultId))?.title, 'Asli');
    },
  );
  test('failed refresh keeps old rows; retry reloads successfully', () async {
    final repo = ControlledHistoryRepository();
    await repo.save(historyDraft());
    final state = AnalysisHistoryProvider(repo);
    addTearDown(state.dispose);
    await state.loadHistory();
    repo.failLoad = true;
    await state.loadHistory();
    expect(state.items, hasLength(1));
    expect(state.loadError, isNotNull);
    repo.failLoad = false;
    await state.loadHistory();
    expect(state.loadError, isNull);
  });
  test(
    'cursor pagination does not skip a row after deleting first page',
    () async {
      final repo = ControlledHistoryRepository(pageSize: 1);
      for (var i = 0; i < 3; i++) {
        await repo.save(historyDraft(id: 'id-$i'));
      }
      final state = AnalysisHistoryProvider(repo);
      addTearDown(state.dispose);
      await state.loadHistory();
      final firstId = state.items.single.id;
      expect(await state.delete(firstId), isTrue);
      while (state.hasMore) {
        await state.loadHistory(more: true);
      }
      expect(state.items, hasLength(2));
      expect(state.items.map((e) => e.id).toSet(), hasLength(2));
      expect(state.items.any((e) => e.id == firstId), isFalse);
    },
  );
  test('delete failure keeps list; lost delete reply is retryable', () async {
    final repo = ControlledHistoryRepository();
    final state = AnalysisHistoryProvider(repo);
    addTearDown(state.dispose);
    await state.save(historyDraft());
    repo.failDelete = true;
    expect(await state.delete(historyResultId), isFalse);
    expect(state.items, hasLength(1));
    repo.failDelete = false;
    repo.loseDeleteReply = true;
    expect(await state.delete(historyResultId), isFalse);
    expect(state.items, hasLength(1));
    expect(await state.delete(historyResultId), isTrue);
    expect(state.items, isEmpty);
    expect(state.savedFor(historyResultId), isNull);
  });
  test(
    'new provider reloads snapshots from repository, independent of active profiles',
    () async {
      final repo = ControlledHistoryRepository();
      final first = AnalysisHistoryProvider(repo);
      await first.save(historyDraft());
      first.dispose();
      final reopened = AnalysisHistoryProvider(repo);
      addTearDown(reopened.dispose);
      await reopened.loadHistory();
      final saved = await reopened.loadDetail(reopened.items.single.id);
      expect(saved!.snapshot.profile.chestCm, 94);
      expect(saved.snapshot.recommendedLabels, ['M']);
      expect(await reopened.loadDetail('missing'), isNull);
    },
  );
  test(
    'disposed account ignores late response and new account starts empty',
    () async {
      final repo = ControlledHistoryRepository()..saveGate = Completer<void>();
      final old = AnalysisHistoryProvider(repo);
      final pending = old.save(historyDraft());
      old.dispose();
      final next = AnalysisHistoryProvider(ControlledHistoryRepository());
      addTearDown(next.dispose);
      await next.loadHistory();
      repo.saveGate!.complete();
      expect(await pending, isNull);
      expect(old.items, isEmpty);
      expect(next.items, isEmpty);
    },
  );
}

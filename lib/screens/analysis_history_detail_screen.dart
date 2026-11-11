import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/analysis_history.dart';
import '../providers/analysis_history_provider.dart';
import '../utils/history_date.dart';
import '../widgets/analysis_result_details.dart';

Future<void> openAnalysisHistoryDetail(BuildContext context, String id) {
  final history = context.read<AnalysisHistoryProvider>();
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider<AnalysisHistoryProvider>.value(
        value: history,
        child: AnalysisHistoryDetailScreen(analysisId: id),
      ),
    ),
  );
}

class AnalysisHistoryDetailScreen extends StatefulWidget {
  final String analysisId;
  const AnalysisHistoryDetailScreen({super.key, required this.analysisId});
  @override
  State<AnalysisHistoryDetailScreen> createState() =>
      _AnalysisHistoryDetailScreenState();
}

class _AnalysisHistoryDetailScreenState
    extends State<AnalysisHistoryDetailScreen> {
  late Future<AnalysisHistoryEntry?> _request;
  @override
  void initState() {
    super.initState();
    _request = context.read<AnalysisHistoryProvider>().loadDetail(
      widget.analysisId,
    );
  }

  void _reload() => setState(() {
    _request = context.read<AnalysisHistoryProvider>().loadDetail(
      widget.analysisId,
    );
  });
  Future<void> _delete(AnalysisHistoryEntry entry) async {
    final history = context.read<AnalysisHistoryProvider>();
    if (history.isBusy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus riwayat ini?'),
        content: Text(
          'Hasil “${entry.title}” akan dihapus. Profil ukuran tubuh tetap tersimpan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            key: const ValueKey('confirmDeleteHistory'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final deleted = await history.delete(entry.id);
    if (!mounted || !deleted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(const SnackBar(content: Text('Riwayat dihapus.')));
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<AnalysisHistoryProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Detail riwayat')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: FutureBuilder<AnalysisHistoryEntry?>(
              future: _request,
              builder: (context, state) {
                if (state.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.hasError || state.data == null) {
                  return ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text(
                        state.hasError
                            ? 'Detail riwayat belum dapat dibuka. Periksa koneksi atau versi aplikasi.'
                            : 'Riwayat tidak ditemukan. Data mungkin sudah dihapus.',
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: _reload,
                        child: const Text('Coba lagi'),
                      ),
                    ],
                  );
                }
                final entry = state.data!;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    Text(
                      entry.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text('Disimpan ${historyDate(entry.createdAt)}'),
                    Text(
                      'Dianalisis ${historyDate(entry.snapshot.analyzedAt)}',
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Ini hasil pada saat disimpan. Perubahan profil berikutnya tidak mengubah riwayat ini.',
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      key: const ValueKey('deleteHistory'),
                      onPressed: history.isBusy ? null : () => _delete(entry),
                      icon: const Icon(Icons.delete_outline),
                      label: Text(
                        history.isDeleting ? 'Menghapus...' : 'Hapus riwayat',
                      ),
                    ),
                    if (history.deleteErrorId == entry.id &&
                        history.deleteError != null)
                      Text(
                        history.deleteError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    const SizedBox(height: 16),
                    AnalysisResultDetails(snapshot: entry.snapshot),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

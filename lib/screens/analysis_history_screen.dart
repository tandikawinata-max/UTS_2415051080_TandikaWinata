import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/analysis_history_provider.dart';
import '../widgets/analysis_history_tile.dart';
import '../widgets/empty_state.dart';

class AnalysisHistoryScreen extends StatelessWidget {
  const AnalysisHistoryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final history = context.watch<AnalysisHistoryProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Analisis'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang riwayat',
            onPressed: history.isBusy ? null : () => history.loadHistory(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: RefreshIndicator(
              onRefresh: () => history.loadHistory(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  Text(
                    'Ukuran yang pernah kamu periksa',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Buka hasil tersimpan untuk melihat profil, tabel, dan perbandingan saat itu.',
                  ),
                  const SizedBox(height: 24),
                  if (history.isLoading) const LinearProgressIndicator(),
                  if (history.loadError != null) ...[
                    Text(
                      history.loadError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    OutlinedButton(
                      key: const ValueKey('retryHistory'),
                      onPressed: history.isBusy
                          ? null
                          : () => history.loadHistory(),
                      child: const Text('Coba lagi'),
                    ),
                  ],
                  if (history.items.isEmpty &&
                      !history.isLoading &&
                      history.loadError == null)
                    const EmptyState(
                      icon: Icons.history,
                      title: 'Belum ada analisis tersimpan',
                      message:
                          'Selesaikan analisis screenshot, lalu pilih Simpan hasil.',
                    ),
                  for (final entry in history.items)
                    AnalysisHistoryTile(entry: entry),
                  if (history.hasMore)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: OutlinedButton(
                        key: const ValueKey('moreHistory'),
                        onPressed: history.isBusy
                            ? null
                            : () => history.loadHistory(more: true),
                        child: const Text('Muat lebih banyak'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/reviewed_size_chart.dart';
import '../providers/measurement_provider.dart';
import '../providers/analysis_history_provider.dart';
import '../providers/screenshot_provider.dart';
import '../providers/size_analysis_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/measurement_status_card.dart';
import 'size_analysis_screen.dart';
import 'measurement_list_screen.dart';
import 'size_chart_review_screen.dart';

class OcrTestScreen extends StatelessWidget {
  const OcrTestScreen({super.key});

  String _progressMessage(ScreenshotPhase phase) => switch (phase) {
    ScreenshotPhase.idle => '',
    ScreenshotPhase.recovering => 'Memeriksa screenshot yang tertunda...',
    ScreenshotPhase.choosing => 'Membuka galeri...',
    ScreenshotPhase.reading => 'Membaca dan menyusun tabel ukuran...',
  };

  Future<bool> _openReview(BuildContext context) async {
    final state = context.read<ScreenshotProvider>();
    final path = state.imagePath;
    if (state.isBusy || path == null) return false;
    final revision = state.revision;
    final chart = await Navigator.of(context).push<ReviewedSizeChart>(
      MaterialPageRoute<ReviewedSizeChart>(
        builder: (_) => SizeChartReviewScreen(
          imagePath: path,
          ocrText: state.recognizedText,
          draft: state.buildChartDraft(),
          initialChart: state.reviewedChart,
        ),
      ),
    );
    if (!context.mounted || chart == null) return false;
    final accepted = state.confirmChart(chart, expectedRevision: revision);
    if (!accepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Screenshot sudah berubah. Periksa hasil pembacaan terbaru.',
          ),
        ),
      );
    }
    return accepted;
  }

  Future<void> _analyze(BuildContext context) async {
    final screenshots = context.read<ScreenshotProvider>();
    if (screenshots.isBusy || !screenshots.hasImage) return;
    if (screenshots.reviewedChart == null) {
      try {
        final chart = screenshots.buildChartDraft().confirm(
          imagePath: screenshots.imagePath!,
          ocrText: screenshots.recognizedText,
        );
        if (!screenshots.confirmChart(
          chart,
          expectedRevision: screenshots.revision,
        )) {
          return;
        }
      } on FormatException {
        if (!await _openReview(context) || !context.mounted) return;
      }
    }
    if (!context.mounted) return;
    final analysis = context.read<SizeAnalysisProvider>();
    if (!analysis.analyze()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            analysis.errorMessage ?? 'Periksa data sebelum analisis.',
          ),
        ),
      );
      return;
    }
    final history = context.read<AnalysisHistoryProvider>();
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider<SizeAnalysisProvider>.value(value: analysis),
            ChangeNotifierProvider<AnalysisHistoryProvider>.value(
              value: history,
            ),
          ],
          child: const SizeAnalysisScreen(),
        ),
      ),
    );
  }

  Widget _table(BuildContext context, List<SizeChartDraftRow> rows) {
    Widget cell(String text, {bool requiredValue = false, bool label = false}) {
      final invalid = label
          ? SizeChartRules.label(text) != null
          : SizeChartRules.number(text, requiredValue: requiredValue) != null;
      return Text(
        text.isEmpty ? (requiredValue ? 'Perlu diperiksa' : '—') : text,
        style: invalid
            ? TextStyle(color: Theme.of(context).colorScheme.error)
            : null,
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight:
            56 *
            (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(
              1.0,
              double.infinity,
            ),
        dataRowMaxHeight: double.infinity,
        columns: const [
          DataColumn(label: Text('Ukuran')),
          DataColumn(label: Text('Dada')),
          DataColumn(label: Text('Pinggang')),
          DataColumn(label: Text('Pinggul')),
          DataColumn(label: Text('Bahu')),
        ],
        rows: [
          for (final row in rows)
            DataRow(
              cells: [
                DataCell(cell(row.label, label: true, requiredValue: true)),
                DataCell(cell(row.chest, requiredValue: true)),
                DataCell(cell(row.waist)),
                DataCell(cell(row.hip)),
                DataCell(cell(row.shoulder)),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<ScreenshotProvider>();
    final measurements = context.watch<MeasurementProvider>();
    final path = state.imagePath;
    final chart = state.reviewedChart;
    final draft = state.buildChartDraft();
    final rows = chart?.inputRows ?? draft.rows;
    final basis = chart?.basis ?? draft.basis;
    final rangeMeaning = chart?.rangeMeaning ?? draft.rangeMeaning;
    String? incomplete;
    if (chart == null && path != null && !state.isBusy) {
      try {
        draft.confirm(imagePath: path, ocrText: state.recognizedText);
      } on FormatException catch (e) {
        incomplete = e.message;
      }
    }
    final profileReady =
        measurements.activeMeasurement != null &&
        !measurements.isBusy &&
        measurements.errorMessage == null;
    return Scaffold(
      appBar: AppBar(title: const Text('Analisis screenshot')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                const MeasurementStatusCard(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const MeasurementListScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.person_outline),
                    label: const Text('Pilih profil tubuh'),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Temukan ukuran pakaianmu',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pilih screenshot panduan ukuran tubuh atau ukuran pakaian atasan. Angka dan rentang akan diisi otomatis.',
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  key: const ValueKey('pickScreenshot'),
                  onPressed: state.isBusy ? null : state.pickScreenshot,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(
                    state.hasImage ? 'Ganti screenshot' : 'Pilih screenshot',
                  ),
                ),
                if (state.hasImage)
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        key: const ValueKey('retryOcr'),
                        onPressed: state.isBusy ? null : state.readAgain,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Baca ulang'),
                      ),
                      TextButton.icon(
                        key: const ValueKey('clearScreenshot'),
                        onPressed: state.isBusy ? null : state.clearScreenshot,
                        icon: const Icon(Icons.clear),
                        label: const Text('Kosongkan'),
                      ),
                    ],
                  ),
                if (state.isBusy) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(),
                  Text(
                    _progressMessage(state.phase),
                    key: const ValueKey('screenshotProgress'),
                  ),
                ],
                if (state.noticeMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      state.noticeMessage!,
                      key: const ValueKey('recoveredScreenshot'),
                    ),
                  ),
                const SizedBox(height: 16),
                if (path == null)
                  const EmptyState(
                    icon: Icons.photo_outlined,
                    title: 'Belum ada screenshot',
                    message: 'Pilih gambar tabel ukuran dari galeri perangkat.',
                  )
                else
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: SizedBox(
                      height: 220,
                      child: InteractiveViewer(
                        key: ValueKey(path),
                        minScale: 1,
                        maxScale: 5,
                        child: Image.file(
                          File(path),
                          fit: BoxFit.contain,
                          cacheWidth: 1600,
                          errorBuilder: (_, error, stack) => const Center(
                            child: Text('Pratinjau gambar tidak tersedia.'),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (state.errorMessage != null)
                  Text(
                    state.errorMessage!,
                    key: const ValueKey('screenshotError'),
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                if (path != null && !state.isBusy) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Hasil pembacaan tabel',
                    key: const ValueKey('automaticChartTitle'),
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (rows.isEmpty)
                    const Text(
                      'Tabel belum dapat disusun. Coba gambar yang lebih jelas, atau gunakan input manual.',
                    )
                  else ...[
                    Text(
                      'Jenis tabel: ${basis?.label ?? 'Perlu dikonfirmasi'}',
                    ),
                    if (basis == ChartBasis.garment &&
                        rows.any((row) => row.hasRange))
                      Text(
                        'Makna rentang: ${rangeMeaning?.label ?? 'Perlu dikonfirmasi'}',
                      ),
                    Text(
                      'Satuan: ${(chart?.unit ?? draft.unit)?.label ?? 'Perlu dikonfirmasi'}',
                    ),
                    if (basis != ChartBasis.body)
                      Text(
                        'Dada: ${(chart?.chestType ?? draft.chestType)?.label ?? 'Perlu dikonfirmasi'}',
                      ),
                    if (basis != ChartBasis.body &&
                        rows.any((r) => !SizeChartRules.isEmptyValue(r.waist)))
                      Text(
                        'Pinggang: ${(chart?.waistType ?? draft.waistType)?.label ?? 'Perlu dikonfirmasi'}',
                      ),
                    if (basis != ChartBasis.body &&
                        rows.any((r) => !SizeChartRules.isEmptyValue(r.hip)))
                      Text(
                        'Pinggul: ${(chart?.hipType ?? draft.hipType)?.label ?? 'Perlu dikonfirmasi'}',
                      ),
                    _table(context, rows),
                    Text(
                      basis == ChartBasis.body
                          ? 'Rentang tubuh dicocokkan langsung dengan profil. Tidak ada tambahan kelonggaran.'
                          : 'Angka mengikuti sumber. Kedua batas dikonversi saat analisis; lebar bentang dikalikan dua dan bahu tetap lebar.',
                    ),
                  ],
                  if (chart == null && draft.warnings.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(draft.warnings.join('\n')),
                    ),
                  if (incomplete != null && rows.isNotEmpty)
                    Text(
                      incomplete,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    key: const ValueKey('openChartReview'),
                    onPressed: () => _openReview(context),
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(
                      rows.isEmpty
                          ? 'Input tabel manual'
                          : 'Koreksi atau lengkapi tabel',
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!profileReady)
                    const Text(
                      'Pilih profil tubuh aktif dan pastikan datanya selesai dimuat sebelum analisis.',
                    ),
                  FilledButton.icon(
                    key: const ValueKey('openSizeAnalysis'),
                    onPressed: profileReady && rows.isNotEmpty
                        ? () => _analyze(context)
                        : null,
                    icon: const Icon(Icons.compare_arrows),
                    label: Text(
                      incomplete == null
                          ? 'Analisis ukuran'
                          : 'Periksa data lalu analisis',
                    ),
                  ),
                  const Text(
                    'Menekan Analisis ukuran menggunakan angka, satuan, dan jenis tabel yang ditampilkan.',
                  ),
                  const SizedBox(height: 16),
                  ExpansionTile(
                    title: const Text('Lihat teks hasil pembacaan'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: SelectableText(
                          state.recognizedText.isEmpty
                              ? 'Belum ada teks yang ditampilkan.'
                              : state.recognizedText,
                          key: const ValueKey('recognizedText'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

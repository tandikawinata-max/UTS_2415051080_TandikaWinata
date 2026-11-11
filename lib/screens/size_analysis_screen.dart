import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/size_analysis_result.dart';
import '../models/reviewed_size_chart.dart';
import '../providers/size_analysis_provider.dart';
import 'measurement_list_screen.dart';

class SizeAnalysisScreen extends StatelessWidget {
  const SizeAnalysisScreen({super.key});
  String _number(double? value) =>
      value == null ? '—' : value.toStringAsFixed(2);

  Widget _evaluation(
    BuildContext context,
    SizeEvaluation row,
    bool recommended,
    bool isBody,
  ) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ukuran ${row.label}${recommended ? ' · Kandidat' : ''}',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              isBody && row.verdict == SizeFitVerdict.meetsTarget
                  ? 'Profil masuk rentang tabel'
                  : row.verdict.label,
            ),
            if (row.hasMissingRequiredData)
              const Text('Ada data wajib penilaian yang belum tersedia.'),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text('Bagian')),
                  DataColumn(label: Text('Tubuh\n(cm)')),
                  DataColumn(
                    label: Text(
                      isBody ? 'Rentang tubuh tabel\n(cm)' : 'Pakaian\n(cm)',
                    ),
                  ),
                  if (!isBody) const DataColumn(label: Text('Selisih\n(cm)')),
                  DataColumn(label: Text('Penilaian')),
                ],
                rows: [
                  for (final c in row.comparisons)
                    DataRow(
                      cells: [
                        DataCell(Text(c.dimension.label)),
                        DataCell(Text(_number(c.bodyCm))),
                        DataCell(Text(c.chartCm?.format() ?? '—')),
                        if (!isBody)
                          DataCell(
                            Text(c.differenceCm?.format(signed: true) ?? '—'),
                          ),
                        DataCell(Text(c.status.label)),
                      ],
                    ),
                ],
              ),
            ),
            if (row.distanceFromTargetCm != null)
              Text(
                'Rata-rata jarak batas terjauh dari target: ${_number(row.distanceFromTargetCm)} cm.',
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SizeAnalysisProvider>();
    final result = state.canAnalyze ? state.result : null;
    final theme = Theme.of(context);
    final isBody = state.chart?.basis == ChartBasis.body;
    return Scaffold(
      appBar: AppBar(title: const Text('Hasil analisis ukuran')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                Text(
                  'Profil aktif: ${state.profile?.label ?? 'Belum dipilih'}',
                  style: theme.textTheme.titleLarge,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const MeasurementListScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.person_outline),
                    label: const Text('Pilih atau kelola profil'),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Jenis tabel: ${state.chart?.basis.label ?? 'Belum tersedia'}',
                ),
                if (isBody)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'Profil dicocokkan langsung dengan rentang tubuh. Preferensi kelonggaran tidak diterapkan.',
                    ),
                  ),
                if (!isBody) ...[
                  DropdownButtonFormField<FitPreference>(
                    key: ValueKey(state.preference),
                    initialValue: state.preference,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Preferensi kelonggaran',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final fit in FitPreference.values)
                        DropdownMenuItem(value: fit, child: Text(fit.label)),
                    ],
                    onChanged: (value) {
                      if (value != null) state.setPreference(value);
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Target tambahan lingkar: ${state.preference.minEaseCm.toStringAsFixed(0)}–${state.preference.maxEaseCm.toStringAsFixed(0)} cm.',
                  ),
                  const Text(
                    'Aturan awal Usize untuk pakaian atasan. Bukan standar ukuran semua merek.',
                  ),
                ],
                if (state.blockedReason != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(state.blockedReason!),
                  ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  key: const ValueKey('runSizeAnalysis'),
                  onPressed: state.canAnalyze
                      ? () {
                          state.analyze();
                        }
                      : null,
                  icon: const Icon(Icons.compare_arrows),
                  label: const Text('Hitung perbandingan'),
                ),
                if (state.errorMessage != null)
                  Text(
                    state.errorMessage!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                if (state.noticeMessage != null) Text(state.noticeMessage!),
                if (result != null) ...[
                  const SizedBox(height: 24),
                  Card(
                    color: theme.colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result.recommendedLabels.isEmpty
                                ? 'Belum ada kandidat yang memenuhi target'
                                : result.recommendedLabels.length == 1
                                ? 'Kandidat: ${result.recommendedLabels.single}'
                                : '${isBody ? 'Kandidat sesuai rentang' : 'Kandidat setara'}: ${result.recommendedLabels.join(', ')}',
                            key: const ValueKey('analysisRecommendation'),
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            result.recommendedLabels.isEmpty
                                ? 'Periksa rincian: data dapat berada di luar rentang, hanya sebagian memenuhi target, atau masih memerlukan informasi.'
                                : isBody
                                ? 'Profil masuk seluruh rentang tubuh yang digunakan untuk penilaian.'
                                : 'Seluruh rentang selisih kandidat memenuhi target. Kandidat dipilih berdasarkan jarak batas terjauh dari titik tengah target.',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Dasar penilaian: ${result.requiredDimensions.map((d) => d.label).join(', ')}.',
                  ),
                  if (!isBody)
                    Text(
                      'Titik tengah target: ${_number(result.preference.targetEaseCm)} cm.',
                    ),
                  const SizedBox(height: 12),
                  for (final note in result.notes)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(note),
                    ),
                  Text(
                    isBody
                        ? 'Geser tabel untuk melihat seluruh kolom. Ukuran profil dibandingkan dengan kedua batas rentang.'
                        : 'Selisih = ukuran pakaian − ukuran tubuh. Nilai negatif berarti pakaian lebih kecil. Geser tabel untuk melihat seluruh kolom.',
                  ),
                  const SizedBox(height: 16),
                  for (final row in result.evaluations)
                    _evaluation(
                      context,
                      row,
                      result.recommendedLabels.contains(row.label),
                      isBody,
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

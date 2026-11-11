import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/size_analysis_result.dart';
import '../models/analysis_history.dart';
import '../widgets/analysis_result_details.dart';
import '../widgets/analysis_save_card.dart';
import '../models/reviewed_size_chart.dart';
import '../providers/size_analysis_provider.dart';
import 'measurement_list_screen.dart';

class SizeAnalysisScreen extends StatelessWidget {
  const SizeAnalysisScreen({super.key});
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
                  AnalysisSaveCard(key: ValueKey(result.id), result: result),
                  const SizedBox(height: 16),
                  AnalysisResultDetails(
                    snapshot: AnalysisSnapshot.fromResult(result),
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

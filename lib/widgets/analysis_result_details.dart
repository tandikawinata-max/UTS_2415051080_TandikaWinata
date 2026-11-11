import 'package:flutter/material.dart';
import '../models/analysis_history.dart';
import '../models/reviewed_size_chart.dart';
import '../models/size_analysis_result.dart';

class AnalysisResultDetails extends StatelessWidget {
  final AnalysisSnapshot snapshot;
  const AnalysisResultDetails({super.key, required this.snapshot});
  String _number(double? value) =>
      value == null ? '—' : value.toStringAsFixed(2);
  Widget _evaluation(BuildContext context, SizeEvaluation row) {
    final isBody = snapshot.basis == ChartBasis.body;
    final recommended = snapshot.recommendedLabels.contains(row.label);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ukuran ${row.label}${recommended ? ' · Kandidat' : ''}',
              style: Theme.of(context).textTheme.titleLarge,
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
                  const DataColumn(label: Text('Bagian')),
                  const DataColumn(label: Text('Tubuh\n(cm)')),
                  DataColumn(
                    label: Text(
                      isBody ? 'Rentang tubuh tabel\n(cm)' : 'Pakaian\n(cm)',
                    ),
                  ),
                  if (!isBody) const DataColumn(label: Text('Selisih\n(cm)')),
                  const DataColumn(label: Text('Penilaian')),
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
    final theme = Theme.of(context);
    final isBody = snapshot.basis == ChartBasis.body;
    final labels = snapshot.recommendedLabels;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: theme.colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  labels.isEmpty
                      ? 'Belum ada kandidat yang memenuhi target'
                      : labels.length == 1
                      ? 'Kandidat: ${labels.single}'
                      : '${isBody ? 'Kandidat sesuai rentang' : 'Kandidat setara'}: ${labels.join(', ')}',
                  key: const ValueKey('analysisRecommendation'),
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  labels.isEmpty
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
        Text('Profil saat dianalisis: ${snapshot.profile.label}'),
        Text('Jenis tabel: ${snapshot.basis.label}'),
        Text(
          'Dasar penilaian: ${snapshot.requiredDimensions.map((d) => d.label).join(', ')}.',
        ),
        if (!isBody)
          Text(
            'Preferensi: ${snapshot.preference.label} · titik tengah target ${_number(snapshot.preference.targetEaseCm)} cm.',
          ),
        const SizedBox(height: 12),
        for (final note in snapshot.notes)
          Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(note)),
        Text(
          isBody
              ? 'Geser tabel untuk melihat seluruh kolom. Ukuran profil dibandingkan dengan kedua batas rentang.'
              : 'Selisih = ukuran pakaian − ukuran tubuh. Nilai negatif berarti pakaian lebih kecil. Geser tabel untuk melihat seluruh kolom.',
        ),
        const SizedBox(height: 16),
        for (final row in snapshot.evaluations) _evaluation(context, row),
        const SizedBox(height: 16),
        Card(
          child: ExpansionTile(
            title: const Text('Tabel yang digunakan'),
            subtitle: Text('Angka sumber dalam ${snapshot.unit.symbol}'),
            childrenPadding: const EdgeInsets.all(16),
            children: [
              if (!isBody) ...[
                Text('Dada: ${snapshot.chestType.label}'),
                if (snapshot.waistType != null)
                  Text('Pinggang: ${snapshot.waistType!.label}'),
                if (snapshot.hipType != null)
                  Text('Pinggul: ${snapshot.hipType!.label}'),
                if (snapshot.rangeMeaning != null)
                  Text('Makna rentang: ${snapshot.rangeMeaning!.label}'),
              ],
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Ukuran')),
                    DataColumn(label: Text('Dada')),
                    DataColumn(label: Text('Pinggang')),
                    DataColumn(label: Text('Pinggul')),
                    DataColumn(label: Text('Bahu')),
                  ],
                  rows: [
                    for (final row in snapshot.inputRows)
                      DataRow(
                        cells: [
                          for (final value in [
                            row.label,
                            row.chest,
                            row.waist,
                            row.hip,
                            row.shoulder,
                          ])
                            DataCell(Text(value.isEmpty ? '—' : value)),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

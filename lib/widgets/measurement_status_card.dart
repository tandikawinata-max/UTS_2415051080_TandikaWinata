import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/measurement_provider.dart';

class MeasurementStatusCard extends StatelessWidget {
  const MeasurementStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MeasurementProvider>();
    final activeMeasurement = state.activeMeasurement;
    final errorMessage = state.errorMessage;
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profil untuk analisis',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (state.isLoading) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              const Text('Memuat profil...'),
            ] else if (errorMessage != null) ...[
              Text(
                errorMessage,
                style: TextStyle(color: theme.colorScheme.error),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  context.read<MeasurementProvider>().loadMeasurements();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
              ),
            ] else if (activeMeasurement == null) ...[
              const Text('Belum ada profil aktif'),
              const SizedBox(height: 4),
              const Text(
                'Buka daftar profil dan pilih profil yang ingin digunakan.',
              ),
            ] else ...[
              Text('Profil aktif: ${activeMeasurement.label}'),
              const SizedBox(height: 4),
              Text(
                'Lingkar dada: '
                '${activeMeasurement.chestCm.toStringAsFixed(1)} cm',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

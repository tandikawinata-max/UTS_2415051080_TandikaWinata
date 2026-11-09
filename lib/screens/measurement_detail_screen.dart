import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/measurement_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/measurement_status_card.dart';

class MeasurementDetailScreen extends StatelessWidget {
  final String measurementId;

  const MeasurementDetailScreen({super.key, required this.measurementId});

  String _formatMeasurement(double? value, String unit) {
    if (value == null) {
      return 'Belum diisi';
    }

    return '${value.toStringAsFixed(1)} $unit';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MeasurementProvider>();
    final measurement = state.findById(measurementId);
    final theme = Theme.of(context);

    if (measurement == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Profil')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const MeasurementStatusCard(),
              const SizedBox(height: 16),
              if (!state.isLoading && state.errorMessage == null)
                const EmptyState(
                  icon: Icons.person_off_outlined,
                  title: 'Profil tidak ditemukan',
                  message:
                      'Kembali ke daftar untuk memilih profil yang tersedia.',
                ),
            ],
          ),
        ),
      );
    }

    final isActive = state.activeMeasurementId == measurement.id;
    final date = measurement.measuredAt.toLocal();
    final formattedDate =
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';

    final measurements = <String, String>{
      'Lingkar dada': _formatMeasurement(measurement.chestCm, 'cm'),
      'Lingkar pinggang': _formatMeasurement(measurement.waistCm, 'cm'),
      'Lingkar pinggul': _formatMeasurement(measurement.hipCm, 'cm'),
      'Lebar bahu': _formatMeasurement(measurement.shoulderWidthCm, 'cm'),
      'Tinggi badan': _formatMeasurement(measurement.heightCm, 'cm'),
      'Berat badan': _formatMeasurement(measurement.weightKg, 'kg'),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Profil')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  measurement.label,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Diukur pada $formattedDate'),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: isActive
                      ? null
                      : () {
                          context.read<MeasurementProvider>().selectMeasurement(
                            measurement.id,
                          );

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${measurement.label} menjadi profil aktif.',
                              ),
                            ),
                          );
                        },
                  icon: Icon(
                    isActive ? Icons.check_circle : Icons.check_circle_outline,
                  ),
                  label: Text(
                    isActive ? 'Profil ini aktif' : 'Gunakan profil ini',
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (final entry in measurements.entries)
                        ListTile(
                          title: Text(entry.key),
                          subtitle: Text(entry.value),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

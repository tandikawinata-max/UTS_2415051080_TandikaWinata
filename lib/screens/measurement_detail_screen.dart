import 'package:flutter/material.dart';

import '../models/body_measurement.dart';

class MeasurementDetailScreen extends StatelessWidget {
  final BodyMeasurement measurement;

  const MeasurementDetailScreen({super.key, required this.measurement});

  String _formatMeasurement(double? value, String unit) {
    if (value == null) {
      return 'Belum diisi';
    }

    return '${value.toStringAsFixed(1)} $unit';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                const SizedBox(height: 24),
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

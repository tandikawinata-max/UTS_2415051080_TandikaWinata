import 'package:flutter/material.dart';

import '../models/body_measurement.dart';

class MeasurementCard extends StatelessWidget {
  final BodyMeasurement measurement;
  final VoidCallback? onTap;

  const MeasurementCard({super.key, required this.measurement, this.onTap});

  String _formatMeasurement(double? value) {
    if (value == null) {
      return 'Belum diisi';
    }

    return '${value.toStringAsFixed(1)} cm';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.person_outline, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      measurement.label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (onTap != null) const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Lingkar dada: '
                '${_formatMeasurement(measurement.chestCm)}',
              ),
              const SizedBox(height: 8),
              Text(
                'Lingkar pinggang: '
                '${_formatMeasurement(measurement.waistCm)}',
              ),
              const SizedBox(height: 8),
              Text(
                'Lingkar pinggul: '
                '${_formatMeasurement(measurement.hipCm)}',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

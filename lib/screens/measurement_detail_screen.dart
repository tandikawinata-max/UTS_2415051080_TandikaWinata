import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/body_measurement.dart';
import '../providers/measurement_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/measurement_status_card.dart';
import 'measurement_form_screen.dart';

class MeasurementDetailScreen extends StatelessWidget {
  final String measurementId;

  const MeasurementDetailScreen({super.key, required this.measurementId});

  Future<void> _openEdit(
    BuildContext context,
    BodyMeasurement measurement,
  ) async {
    context.read<MeasurementProvider>().clearSaveError();

    final saved = await Navigator.of(context).push<BodyMeasurement>(
      MaterialPageRoute<BodyMeasurement>(
        builder: (_) => MeasurementFormScreen(initialMeasurement: measurement),
      ),
    );

    if (!context.mounted || saved == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Profil "${saved.label}" berhasil diperbarui.')),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  Widget _measurementTile(String title, double? value, {String unit = 'cm'}) {
    var text = 'Belum diisi';

    if (value != null) {
      final number = value == value.truncateToDouble()
          ? value.toStringAsFixed(0)
          : value.toString();

      text = '$number $unit';
    }

    return ListTile(title: Text(title), subtitle: Text(text));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MeasurementProvider>();
    final measurement = state.findById(measurementId);
    final isActive = state.activeMeasurementId == measurementId;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Profil'),
        actions: [
          IconButton(
            tooltip: 'Edit profil',
            onPressed: measurement == null || state.isLoading || state.isSaving
                ? null
                : () => _openEdit(context, measurement),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (measurement == null) ...[
                  const MeasurementStatusCard(),
                  const SizedBox(height: 16),
                  if (!state.isLoading && state.errorMessage == null)
                    const EmptyState(
                      icon: Icons.person_off_outlined,
                      title: 'Profil tidak ditemukan',
                      message: 'Kembali ke daftar profil dan muat ulang data.',
                    ),
                ] else ...[
                  Text(
                    measurement.label,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tanggal pengukuran: '
                    '${_formatDate(measurement.measuredAt)}',
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: isActive
                        ? null
                        : () {
                            context
                                .read<MeasurementProvider>()
                                .selectMeasurement(measurement.id);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${measurement.label} '
                                  'menjadi profil aktif.',
                                ),
                              ),
                            );
                          },
                    icon: Icon(
                      isActive
                          ? Icons.check_circle
                          : Icons.check_circle_outline,
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
                        _measurementTile('Lingkar dada', measurement.chestCm),
                        _measurementTile(
                          'Lingkar pinggang',
                          measurement.waistCm,
                        ),
                        _measurementTile('Lingkar pinggul', measurement.hipCm),
                        _measurementTile(
                          'Lebar bahu',
                          measurement.shoulderWidthCm,
                        ),
                        _measurementTile('Tinggi badan', measurement.heightCm),
                        _measurementTile(
                          'Berat badan',
                          measurement.weightKg,
                          unit: 'kg',
                        ),
                      ],
                    ),
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

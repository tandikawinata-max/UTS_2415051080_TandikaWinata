import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/body_measurement.dart';
import '../providers/measurement_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/measurement_status_card.dart';
import 'measurement_form_screen.dart';

class MeasurementDetailScreen extends StatefulWidget {
  final String measurementId;

  const MeasurementDetailScreen({super.key, required this.measurementId});

  @override
  State<MeasurementDetailScreen> createState() =>
      _MeasurementDetailScreenState();
}

class _MeasurementDetailScreenState extends State<MeasurementDetailScreen> {
  bool _confirmingDelete = false;
  bool _deleteInProgress = false;

  Future<void> _openEdit(BodyMeasurement measurement) async {
    final state = context.read<MeasurementProvider>();

    if (state.isBusy || _confirmingDelete || _deleteInProgress) {
      return;
    }

    state.clearSaveError();

    final saved = await Navigator.of(context).push<BodyMeasurement>(
      MaterialPageRoute<BodyMeasurement>(
        builder: (_) => MeasurementFormScreen(initialMeasurement: measurement),
      ),
    );

    if (!mounted || saved == null) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Profil "${saved.label}" berhasil diperbarui.')),
      );
  }

  Future<void> _confirmAndDelete(BodyMeasurement measurement) async {
    final state = context.read<MeasurementProvider>();

    if (state.isBusy || _confirmingDelete || _deleteInProgress) {
      return;
    }

    final isActive = state.activeMeasurementId == measurement.id;

    setState(() {
      _confirmingDelete = true;
    });

    var confirmed = false;

    try {
      confirmed =
          await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) {
              final colors = Theme.of(dialogContext).colorScheme;

              return AlertDialog(
                scrollable: true,
                title: const Text('Hapus profil?'),
                content: Text(
                  'Profil "${measurement.label}" akan dihapus '
                  'secara permanen.'
                  '${isActive ? '\n\nProfil ini sedang aktif. '
                            'Setelah dihapus, pilih profil lain '
                            'untuk analisis.' : ''}',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop(false);
                    },
                    child: const Text('Batal'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.error,
                      foregroundColor: colors.onError,
                    ),
                    onPressed: () {
                      Navigator.of(dialogContext).pop(true);
                    },
                    child: const Text('Hapus'),
                  ),
                ],
              );
            },
          ) ??
          false;
    } finally {
      if (mounted) {
        setState(() {
          _confirmingDelete = false;
        });
      }
    }

    if (!mounted || !confirmed) return;

    setState(() {
      _deleteInProgress = true;
    });

    final success = await state.deleteMeasurement(measurement.id);

    if (!mounted) return;

    if (!success) {
      setState(() {
        _deleteInProgress = false;
      });
      return;
    }

    await WidgetsBinding.instance.endOfFrame;

    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (navigator.canPop()) {
      navigator.pop();
    } else {
      setState(() {
        _deleteInProgress = false;
      });
    }

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('Profil "${measurement.label}" berhasil dihapus.'),
        ),
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
    final measurement = state.findById(widget.measurementId);
    final deleteError = state.deleteErrorFor(widget.measurementId);
    final isActive = state.activeMeasurementId == widget.measurementId;

    final busy = state.isBusy || _confirmingDelete || _deleteInProgress;

    final theme = Theme.of(context);

    return PopScope<Object?>(
      canPop: !state.isDeleting && !_confirmingDelete,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Detail Profil'),
          actions: [
            IconButton(
              tooltip: 'Edit profil',
              onPressed: measurement == null || busy
                  ? null
                  : () => _openEdit(measurement),
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              key: const ValueKey('deleteMeasurement'),
              tooltip: 'Hapus profil',
              color: theme.colorScheme.error,
              onPressed: measurement == null || busy
                  ? null
                  : () => _confirmAndDelete(measurement),
              icon: const Icon(Icons.delete_outline),
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
                  if (_deleteInProgress) ...[
                    const LinearProgressIndicator(),
                    const SizedBox(height: 12),
                    const Text('Menghapus profil...'),
                    const SizedBox(height: 20),
                  ],
                  if (deleteError != null && !_deleteInProgress) ...[
                    Text(
                      deleteError,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (measurement != null)
                          TextButton.icon(
                            onPressed: busy
                                ? null
                                : () => _confirmAndDelete(measurement),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Coba lagi'),
                          ),
                        OutlinedButton.icon(
                          onPressed: busy
                              ? null
                              : () {
                                  context
                                      .read<MeasurementProvider>()
                                      .loadMeasurements();
                                },
                          icon: const Icon(Icons.sync),
                          label: const Text('Muat ulang profil'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (measurement == null) ...[
                    if (!_deleteInProgress) ...[
                      const MeasurementStatusCard(),
                      const SizedBox(height: 16),
                      if (!state.isLoading && state.errorMessage == null)
                        const EmptyState(
                          icon: Icons.person_off_outlined,
                          title: 'Profil tidak ditemukan',
                          message:
                              'Kembali ke daftar profil '
                              'untuk memilih profil lain.',
                        ),
                    ],
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
                      onPressed: isActive || busy
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
                          _measurementTile(
                            'Lingkar pinggul',
                            measurement.hipCm,
                          ),
                          _measurementTile(
                            'Lebar bahu',
                            measurement.shoulderWidthCm,
                          ),
                          _measurementTile(
                            'Tinggi badan',
                            measurement.heightCm,
                          ),
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
      ),
    );
  }
}

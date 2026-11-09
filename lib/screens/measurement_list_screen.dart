import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/body_measurement.dart';
import '../providers/measurement_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/measurement_card.dart';
import '../widgets/measurement_status_card.dart';
import 'measurement_detail_screen.dart';
import 'measurement_form_screen.dart';

class MeasurementListScreen extends StatelessWidget {
  const MeasurementListScreen({super.key});

  Future<void> _openForm(BuildContext context) async {
    context.read<MeasurementProvider>().clearSaveError();

    final saved = await Navigator.of(context).push<BodyMeasurement>(
      MaterialPageRoute<BodyMeasurement>(
        builder: (_) => const MeasurementFormScreen(),
      ),
    );

    if (!context.mounted || saved == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Profil "${saved.label}" berhasil disimpan.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MeasurementProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Profil')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: state.isLoading || state.isSaving
            ? null
            : () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah profil'),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                const MeasurementStatusCard(),
                const SizedBox(height: 16),
                if (state.measurements.isEmpty &&
                    !state.isLoading &&
                    state.errorMessage == null)
                  const EmptyState(
                    icon: Icons.person_outline,
                    title: 'Belum ada profil',
                    message:
                        'Tekan Tambah profil untuk menyimpan '
                        'ukuran tubuh pertamamu.',
                  ),
                for (final measurement in state.measurements)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: MeasurementCard(
                      measurement: measurement,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => MeasurementDetailScreen(
                              measurementId: measurement.id,
                            ),
                          ),
                        );
                      },
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

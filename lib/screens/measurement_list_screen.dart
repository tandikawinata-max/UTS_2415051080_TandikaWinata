import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/measurement_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/measurement_card.dart';
import '../widgets/measurement_status_card.dart';
import 'measurement_detail_screen.dart';

class MeasurementListScreen extends StatelessWidget {
  const MeasurementListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MeasurementProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Profil')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const MeasurementStatusCard(),
                const SizedBox(height: 16),
                if (state.measurements.isEmpty &&
                    !state.isLoading &&
                    state.errorMessage == null)
                  const EmptyState(
                    icon: Icons.person_outline,
                    title: 'Belum ada profil',
                    message: 'Profil ukuran tubuh akan ditampilkan di sini.',
                  ),
                for (final measurement in state.measurements)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: MeasurementCard(
                      measurement: measurement,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) {
                              return MeasurementDetailScreen(
                                measurementId: measurement.id,
                              );
                            },
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

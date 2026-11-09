import 'package:flutter/material.dart';

import '../models/body_measurement.dart';
import '../widgets/empty_state.dart';
import '../widgets/measurement_card.dart';
import 'measurement_detail_screen.dart';

class MeasurementListScreen extends StatelessWidget {
  final List<BodyMeasurement> measurements;

  const MeasurementListScreen({super.key, required this.measurements});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Profil')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: measurements.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(16),
                    children: const [
                      EmptyState(
                        icon: Icons.person_outline,
                        title: 'Belum ada profil',
                        message:
                            'Profil ukuran tubuh akan ditampilkan di sini.',
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: measurements.length,
                    separatorBuilder: (context, index) {
                      return const SizedBox(height: 16);
                    },
                    itemBuilder: (context, index) {
                      final measurement = measurements[index];

                      return MeasurementCard(
                        measurement: measurement,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) {
                                return MeasurementDetailScreen(
                                  measurement: measurement,
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

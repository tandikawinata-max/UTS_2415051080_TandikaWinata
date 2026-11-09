import 'package:flutter/material.dart';

import '../widgets/empty_state.dart';

class AnalysisHistoryScreen extends StatelessWidget {
  const AnalysisHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Analisis')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                EmptyState(
                  icon: Icons.history,
                  title: 'Belum ada analisis tersimpan',
                  message:
                      'Hasil analisis yang kamu simpan akan muncul di sini.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

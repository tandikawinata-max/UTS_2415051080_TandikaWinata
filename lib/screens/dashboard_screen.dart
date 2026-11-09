import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/measurement_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/measurement_card.dart';
import '../widgets/measurement_status_card.dart';
import '../widgets/section_header.dart';
import 'measurement_guide_screen.dart';
import 'measurement_list_screen.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback onOpenAnalysis;

  const DashboardScreen({super.key, required this.onOpenAnalysis});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<MeasurementProvider>();
    final measurements = state.measurements;

    return Scaffold(
      appBar: AppBar(title: const Text('Usize')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
            final horizontalPadding = isWide ? 32.0 : 16.0;

            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    16,
                    horizontalPadding,
                    32,
                  ),
                  children: [
                    Text(
                      'Kenali ukuranmu',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Gunakan ukuran tubuh dan tabel produk '
                      'untuk membantu memilih ukuran pakaian.',
                    ),
                    const SizedBox(height: 20),
                    const MeasurementStatusCard(),
                    const SizedBox(height: 20),
                    Card(
                      margin: EdgeInsets.zero,
                      color: theme.colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.document_scanner_outlined,
                              size: 36,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Baca tabel ukuran dari gambar',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Pilih screenshot dari galeri '
                              'dan periksa teks yang terbaca.',
                              style: TextStyle(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              onPressed: onOpenAnalysis,
                              icon: const Icon(Icons.image_outlined),
                              label: const Text('Buka pembaca tabel'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const MeasurementGuideScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.straighten),
                      label: const Text('Panduan pengukuran'),
                    ),
                    const SizedBox(height: 28),
                    const SectionHeader(
                      title: 'Profil ukuran tubuh',
                      subtitle: 'Data contoh untuk pratinjau tampilan Usize.',
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const MeasurementListScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.list_alt),
                        label: const Text('Lihat semua profil'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (measurements.isEmpty &&
                        !state.isLoading &&
                        state.errorMessage == null)
                      const EmptyState(
                        icon: Icons.person_outline,
                        title: 'Belum ada profil',
                        message:
                            'Profil ukuran tubuh akan ditampilkan di sini.',
                      ),
                    LayoutBuilder(
                      builder: (context, profileConstraints) {
                        const spacing = 16.0;
                        final cardWidth = isWide
                            ? (profileConstraints.maxWidth - spacing) / 2
                            : profileConstraints.maxWidth;

                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: [
                            for (final measurement in measurements)
                              SizedBox(
                                width: cardWidth,
                                child: MeasurementCard(
                                  measurement: measurement,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                    const SectionHeader(
                      title: 'Riwayat analisis',
                      subtitle: 'Tempat melihat kembali hasil yang disimpan.',
                    ),
                    const SizedBox(height: 16),
                    const EmptyState(
                      icon: Icons.history,
                      title: 'Belum ada analisis tersimpan',
                      message:
                          'Hasil analisis yang kamu simpan '
                          'akan muncul di sini.',
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/measurement_guide_provider.dart';
import '../repositories/measurement_guide_repository.dart';
import '../services/measurement_guide_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_header.dart';

class MeasurementGuideScreen extends StatelessWidget {
  final MeasurementGuideRepository? repository;

  const MeasurementGuideScreen({super.key, this.repository});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MeasurementGuideProvider(
        repository ?? MeasurementGuideRepository(MeasurementGuideService()),
      )..loadGuides(),
      child: const _MeasurementGuideView(),
    );
  }
}

class _MeasurementGuideView extends StatelessWidget {
  const _MeasurementGuideView();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MeasurementGuideProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panduan Pengukuran'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: state.isLoading
                ? null
                : () {
                    context.read<MeasurementGuideProvider>().loadGuides();
                  },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                const SectionHeader(
                  title: 'Mengukur tubuh untuk atasan',
                  subtitle:
                      'Siapkan pita ukur. Catat hasil dalam sentimeter '
                      'dan ikuti petunjuk setiap pengukuran.',
                ),
                const SizedBox(height: 24),
                if (state.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Memuat panduan...'),
                      ],
                    ),
                  )
                else if (state.errorMessage != null) ...[
                  EmptyState(
                    icon: Icons.cloud_off_outlined,
                    title: 'Panduan gagal dimuat',
                    message: state.errorMessage!,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: FilledButton.icon(
                      onPressed: () {
                        context.read<MeasurementGuideProvider>().loadGuides();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba lagi'),
                    ),
                  ),
                ] else if (state.guides.isEmpty)
                  const EmptyState(
                    icon: Icons.menu_book_outlined,
                    title: 'Belum ada panduan',
                    message:
                        'Panduan pengukuran belum tersedia. '
                        'Gunakan tombol muat ulang untuk memeriksa kembali.',
                  )
                else
                  for (final guide in state.guides)
                    Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.straighten,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    guide.title,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(guide.instruction),
                            const SizedBox(height: 12),
                            Text(
                              'Satuan: ${guide.unit}',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
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

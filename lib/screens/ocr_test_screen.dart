import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/screenshot_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/measurement_status_card.dart';

class OcrTestScreen extends StatelessWidget {
  const OcrTestScreen({super.key});

  String _progressMessage(ScreenshotPhase phase) {
    return switch (phase) {
      ScreenshotPhase.idle => '',
      ScreenshotPhase.recovering => 'Memeriksa screenshot yang tertunda...',
      ScreenshotPhase.choosing => 'Membuka galeri...',
      ScreenshotPhase.reading => 'Membaca teks pada screenshot...',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<ScreenshotProvider>();
    final imagePath = state.imagePath;

    return Scaffold(
      appBar: AppBar(title: const Text('Usize – Uji OCR')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                const MeasurementStatusCard(),
                const SizedBox(height: 24),
                Text(
                  'Baca tabel ukuran',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pilih screenshot tabel ukuran yang jelas. '
                  'Periksa kembali angka dan satuan pada hasil pembacaan.',
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  key: const ValueKey('pickScreenshot'),
                  onPressed: state.isBusy ? null : state.pickScreenshot,
                  icon: const Icon(Icons.image_outlined),
                  label: Text(
                    state.hasImage ? 'Ganti screenshot' : 'Pilih screenshot',
                  ),
                ),
                if (state.hasImage) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        key: const ValueKey('retryOcr'),
                        onPressed: state.isBusy ? null : state.readAgain,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Baca ulang'),
                      ),
                      TextButton.icon(
                        key: const ValueKey('clearScreenshot'),
                        onPressed: state.isBusy ? null : state.clearScreenshot,
                        icon: const Icon(Icons.clear),
                        label: const Text('Kosongkan'),
                      ),
                    ],
                  ),
                ],
                if (state.isBusy) ...[
                  const SizedBox(height: 20),
                  const LinearProgressIndicator(),
                  const SizedBox(height: 8),
                  Text(
                    _progressMessage(state.phase),
                    key: const ValueKey('screenshotProgress'),
                  ),
                ],
                if (state.noticeMessage != null) ...[
                  const SizedBox(height: 20),
                  Card(
                    margin: EdgeInsets.zero,
                    color: theme.colorScheme.secondaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.restore,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              state.noticeMessage!,
                              key: const ValueKey('recoveredScreenshot'),
                              style: TextStyle(
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                if (imagePath == null)
                  const EmptyState(
                    icon: Icons.photo_outlined,
                    title: 'Belum ada screenshot',
                    message: 'Pilih gambar tabel ukuran dari galeri perangkat.',
                  )
                else ...[
                  Card(
                    margin: EdgeInsets.zero,
                    clipBehavior: Clip.antiAlias,
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: InteractiveViewer(
                        key: ValueKey(imagePath),
                        minScale: 1,
                        maxScale: 5,
                        child: Image.file(
                          File(imagePath),
                          fit: BoxFit.contain,
                          cacheWidth: 1600,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Text(
                                  'Pratinjau gambar tidak tersedia. '
                                  'Silakan pilih ulang screenshot.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cubit gambar untuk memperbesar.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    state.errorMessage!,
                    key: const ValueKey('screenshotError'),
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  'Hasil pembacaan',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(
                      state.recognizedText.isEmpty
                          ? 'Belum ada teks yang ditampilkan.'
                          : state.recognizedText,
                      key: const ValueKey('recognizedText'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Hasil OCR dapat mengandung kesalahan. '
                  'Cocokkan hasil pembacaan dengan gambar sumber.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

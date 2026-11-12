import 'package:flutter/material.dart';
import '../screens/body_scan_screen.dart';
import '../screens/measurement_form_screen.dart';

class BodyScanEntryCard extends StatelessWidget {
  final bool returnToForm;
  final bool enabled;
  const BodyScanEntryCard({
    super.key,
    this.returnToForm = false,
    this.enabled = true,
  });

  Future<void> _open(BuildContext context) async {
    final action = await Navigator.of(context).push<BodyScanAction>(
      MaterialPageRoute(builder: (_) => const BodyScanScreen()),
    );
    if (!context.mounted ||
        returnToForm ||
        action != BodyScanAction.enterManually) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const MeasurementFormScreen()),
    );
  }

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.secondaryContainer,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DEMO', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Ukur tubuh dengan kamera',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Coba pengambilan foto dan alur ukuran tubuh dengan angka simulasi.',
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            key: const ValueKey('openBodyScan'),
            onPressed: enabled ? () => _open(context) : null,
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Coba kamera demo'),
          ),
        ],
      ),
    ),
  );
}

import 'body_measurement.dart';

/// Contoh tetap untuk demonstrasi alur. Foto tidak digunakan menghitung angka.
class BodyScanResult {
  final String photoPath;
  final BodyMeasurement sampleProfile;

  BodyScanResult.demo({required this.photoPath, required DateTime createdAt})
    : sampleProfile = BodyMeasurement(
        id: 'body-camera-demo',
        label: 'Profil demo (simulasi)',
        chestCm: 94,
        waistCm: 80,
        hipCm: 96,
        shoulderWidthCm: 42,
        measuredAt: createdAt,
      );
}

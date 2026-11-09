import '../models/body_measurement.dart';
import 'measurement_repository.dart';

class DemoMeasurementRepository implements MeasurementRepository {
  final Map<String, BodyMeasurement> _items = {};

  DemoMeasurementRepository({List<BodyMeasurement>? initialMeasurements}) {
    final measurements =
        initialMeasurements ??
        [
          BodyMeasurement(
            id: 'demo-01',
            label: 'Profil Contoh A',
            chestCm: 94,
            waistCm: 80,
            hipCm: 96,
            measuredAt: DateTime(2026, 11, 9),
          ),
          BodyMeasurement(
            id: 'demo-02',
            label: 'Profil Contoh B',
            chestCm: 100,
            waistCm: 86,
            hipCm: 102,
            measuredAt: DateTime(2026, 11, 9),
          ),
          BodyMeasurement(
            id: 'demo-03',
            label: 'Profil Contoh C',
            chestCm: 88,
            waistCm: 74,
            measuredAt: DateTime(2026, 11, 9),
          ),
        ];

    for (final measurement in measurements) {
      _items[measurement.id] = measurement;
    }
  }

  @override
  Future<List<BodyMeasurement>> getMeasurements() async {
    return List<BodyMeasurement>.unmodifiable(_items.values);
  }

  @override
  Future<BodyMeasurement> createMeasurement(BodyMeasurement measurement) async {
    if (measurement.id.trim().isEmpty) {
      throw ArgumentError('ID profil harus diisi.');
    }

    if (_items.containsKey(measurement.id)) {
      throw StateError('ID profil sudah digunakan.');
    }

    _items[measurement.id] = measurement;
    return measurement;
  }

  @override
  Future<BodyMeasurement> updateMeasurement(BodyMeasurement measurement) async {
    if (!_items.containsKey(measurement.id)) {
      throw StateError('Profil tidak ditemukan.');
    }

    _items[measurement.id] = measurement;
    return measurement;
  }

  @override
  Future<void> deleteMeasurement(String id) async {
    if (!_items.containsKey(id)) {
      throw StateError('Profil tidak ditemukan.');
    }

    _items.remove(id);
  }
}

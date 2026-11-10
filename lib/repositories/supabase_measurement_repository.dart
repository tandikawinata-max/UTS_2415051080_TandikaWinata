import '../models/body_measurement.dart';
import '../services/measurement_service.dart';
import 'measurement_repository.dart';

class SupabaseMeasurementRepository implements MeasurementRepository {
  final MeasurementService _service;

  SupabaseMeasurementRepository(this._service);

  @override
  Future<List<BodyMeasurement>> getMeasurements() async {
    final rows = await _service.fetchMeasurements();

    return rows.map(BodyMeasurement.fromJson).toList(growable: false);
  }

  @override
  Future<BodyMeasurement> createMeasurement(BodyMeasurement measurement) async {
    final row = await _service.insertMeasurement(measurement);
    return BodyMeasurement.fromJson(row);
  }

  @override
  Future<BodyMeasurement> updateMeasurement(BodyMeasurement measurement) async {
    final row = await _service.updateMeasurement(measurement);
    return BodyMeasurement.fromJson(row);
  }

  @override
  Future<void> deleteMeasurement(String id) async {
    throw UnsupportedError('Penghapusan profil akan dibuat pada Tahap 11.');
  }
}

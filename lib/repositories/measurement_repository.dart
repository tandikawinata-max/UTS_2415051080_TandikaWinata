import '../models/body_measurement.dart';

abstract class MeasurementRepository {
  Future<List<BodyMeasurement>> getMeasurements();

  Future<BodyMeasurement> createMeasurement(BodyMeasurement measurement);

  Future<BodyMeasurement> updateMeasurement(BodyMeasurement measurement);

  Future<void> deleteMeasurement(String id);
}

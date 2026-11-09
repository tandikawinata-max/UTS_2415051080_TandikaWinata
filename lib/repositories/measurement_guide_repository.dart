import '../models/measurement_guide.dart';
import '../services/measurement_guide_service.dart';

class MeasurementGuideRepository {
  final MeasurementGuideService _service;

  MeasurementGuideRepository(this._service);

  Future<List<MeasurementGuide>> getGuides() {
    return _service.fetchGuides();
  }

  void dispose() {
    _service.dispose();
  }
}

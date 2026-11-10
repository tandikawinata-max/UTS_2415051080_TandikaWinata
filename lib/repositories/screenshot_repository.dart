import '../services/ocr_service.dart';
import '../services/screenshot_service.dart';

abstract class ScreenshotRepository {
  Future<String?> pickScreenshot();

  Future<String?> recoverScreenshot();

  Future<String> readText(String imagePath);
}

class DeviceScreenshotRepository implements ScreenshotRepository {
  final ScreenshotService _screenshotService;
  final OcrService _ocrService;

  DeviceScreenshotRepository({
    ScreenshotService? screenshotService,
    OcrService? ocrService,
  }) : _screenshotService = screenshotService ?? ScreenshotService(),
       _ocrService = ocrService ?? const OcrService();

  @override
  Future<String?> pickScreenshot() {
    return _screenshotService.pickScreenshot();
  }

  @override
  Future<String?> recoverScreenshot() {
    return _screenshotService.recoverScreenshot();
  }

  @override
  Future<String> readText(String imagePath) {
    return _ocrService.readText(imagePath);
  }
}

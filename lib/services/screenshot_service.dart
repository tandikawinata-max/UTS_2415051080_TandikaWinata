import 'dart:io';

import 'package:image_picker/image_picker.dart';

class ScreenshotService {
  final ImagePicker _picker;

  ScreenshotService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  Future<String?> pickScreenshot() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      requestFullMetadata: false,
    );

    if (image == null) {
      return null;
    }

    return _validateFile(image);
  }

  Future<String?> recoverScreenshot() async {
    if (!Platform.isAndroid) {
      return null;
    }

    final response = await _picker.retrieveLostData();

    if (response.isEmpty) {
      return null;
    }

    final files = response.files;

    if (files != null && files.isNotEmpty) {
      return _validateFile(files.first);
    }

    final exception = response.exception;

    if (exception != null) {
      throw exception;
    }

    throw StateError('Hasil pemulihan tidak berisi gambar.');
  }

  Future<String> _validateFile(XFile image) async {
    final file = File(image.path);

    if (!await file.exists()) {
      throw FileSystemException('File screenshot tidak ditemukan.', image.path);
    }

    if (await file.length() == 0) {
      throw FileSystemException('File screenshot kosong.', image.path);
    }

    return image.path;
  }
}

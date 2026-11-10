import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  const OcrService();

  Future<String> readText(String imagePath) async {
    final file = File(imagePath);

    if (!await file.exists()) {
      throw FileSystemException('Screenshot sudah tidak tersedia.', imagePath);
    }

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final result = await recognizer.processImage(inputImage);

      return result.text.trim();
    } finally {
      await recognizer.close();
    }
  }
}

import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/ocr_document.dart';

class OcrService {
  const OcrService();

  Future<String> readText(String imagePath) async =>
      (await readDocument(imagePath)).text;

  Future<OcrDocument> readDocument(String imagePath) async {
    final file = File(imagePath);

    if (!await file.exists()) {
      throw FileSystemException('Screenshot sudah tidak tersedia.', imagePath);
    }

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final result = await recognizer.processImage(inputImage);

      return OcrDocument(
        text: result.text.trim(),
        tokens: [
          for (final block in result.blocks)
            for (final line in block.lines)
              for (final element in line.elements)
                OcrToken(
                  text: element.text,
                  left: element.boundingBox.left,
                  top: element.boundingBox.top,
                  right: element.boundingBox.right,
                  bottom: element.boundingBox.bottom,
                ),
        ],
      );
    } finally {
      await recognizer.close();
    }
  }
}

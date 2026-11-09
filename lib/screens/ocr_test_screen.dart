import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/ocr_service.dart';
import '../widgets/measurement_status_card.dart';

class OcrTestScreen extends StatefulWidget {
  const OcrTestScreen({super.key});

  @override
  State<OcrTestScreen> createState() => _OcrTestScreenState();
}

class _OcrTestScreenState extends State<OcrTestScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final OcrService _ocrService = OcrService();

  String? _imagePath;
  String? _errorMessage;
  String _recognizedText = '';
  bool _isProcessing = false;

  Future<void> _pickAndReadImage() async {
    if (_isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final selectedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (!mounted || selectedImage == null) {
        return;
      }

      setState(() {
        _imagePath = selectedImage.path;
        _recognizedText = '';
      });

      final text = await _ocrService.recognizeText(selectedImage.path);

      if (!mounted) {
        return;
      }

      setState(() {
        _recognizedText = text;

        if (text.isEmpty) {
          _errorMessage =
              'Teks belum ditemukan. Pilih screenshot yang lebih jelas.';
        }
      });
    } catch (error) {
      debugPrint('Pemilihan gambar atau OCR gagal: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
            'Gambar gagal diproses. Silakan pilih gambar dan coba lagi.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = _imagePath;
    final errorMessage = _errorMessage;

    return Scaffold(
      appBar: AppBar(title: const Text('Usize — Uji OCR')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const MeasurementStatusCard(),
          const SizedBox(height: 20),
          const Text(
            'Baca tabel ukuran',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pilih screenshot tabel ukuran dari galeri. '
            'Hasil pembacaan teks akan muncul di bawah gambar.',
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _isProcessing ? null : _pickAndReadImage,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Pilih screenshot'),
          ),
          const SizedBox(height: 16),
          if (_isProcessing) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            const Text('Memproses gambar...'),
            const SizedBox(height: 16),
          ],
          if (imagePath != null) ...[
            Image.file(
              File(imagePath),
              height: 240,
              width: double.infinity,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox(
                  height: 120,
                  child: Center(
                    child: Text('Preview gambar tidak dapat ditampilkan.'),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
          if (errorMessage != null) ...[
            Text(
              errorMessage,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 16),
          ],
          const Text(
            'Hasil pembacaan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                _recognizedText.isEmpty
                    ? 'Belum ada teks yang ditampilkan.'
                    : _recognizedText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

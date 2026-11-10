import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:usize/providers/screenshot_provider.dart';
import 'package:usize/repositories/screenshot_repository.dart';

class FakeScreenshotRepository implements ScreenshotRepository {
  String? pickedPath;
  String? recoveredPath;
  String resultText = 'Ukuran M: dada 100 cm';

  bool failRecovery = false;
  bool failReading = false;

  int pickCalls = 0;
  int recoveryCalls = 0;
  int readCalls = 0;

  Completer<String?>? pendingPick;
  Completer<String>? pendingRead;

  @override
  Future<String?> pickScreenshot() async {
    pickCalls++;

    final pending = pendingPick;

    if (pending != null) {
      return pending.future;
    }

    return pickedPath;
  }

  @override
  Future<String?> recoverScreenshot() async {
    recoveryCalls++;

    if (failRecovery) {
      throw StateError('Simulasi kegagalan pemulihan.');
    }

    return recoveredPath;
  }

  @override
  Future<String> readText(String imagePath) async {
    readCalls++;

    if (failReading) {
      throw StateError('Simulasi kegagalan OCR.');
    }

    final pending = pendingRead;

    if (pending != null) {
      return pending.future;
    }

    return resultText;
  }
}

void main() {
  group('ScreenshotProvider', () {
    late FakeScreenshotRepository repository;
    late ScreenshotProvider state;

    setUp(() {
      repository = FakeScreenshotRepository();
      state = ScreenshotProvider(repository);
    });

    tearDown(() {
      state.dispose();
    });

    test('memulihkan screenshot dan hanya memeriksa satu kali', () async {
      repository.recoveredPath = '/recovered.png';

      final recovered = await state.initialize();

      expect(recovered, isTrue);
      expect(state.imagePath, '/recovered.png');
      expect(state.recognizedText, repository.resultText);
      expect(state.noticeMessage, contains('berhasil dipulihkan'));
      expect(state.isBusy, isFalse);

      expect(await state.initialize(), isFalse);
      expect(repository.recoveryCalls, 1);
      expect(repository.readCalls, 1);
    });

    test('tanpa data tertunda tidak menjalankan OCR', () async {
      final recovered = await state.initialize();

      expect(recovered, isFalse);
      expect(state.imagePath, isNull);
      expect(repository.readCalls, 0);
      expect(state.errorMessage, isNull);
      expect(state.isBusy, isFalse);
    });

    test('pemulihan gagal tetap mengizinkan pemilihan manual', () async {
      repository.failRecovery = true;

      expect(await state.initialize(), isFalse);
      expect(state.errorMessage, contains('belum dapat dipulihkan'));
      expect(state.isBusy, isFalse);

      repository.pickedPath = '/manual.png';
      await state.pickScreenshot();

      expect(state.imagePath, '/manual.png');
      expect(state.recognizedText, repository.resultText);
      expect(state.errorMessage, isNull);
    });

    test('membatalkan galeri mempertahankan hasil sebelumnya', () async {
      repository.pickedPath = '/first.png';
      await state.pickScreenshot();

      final previousText = state.recognizedText;

      repository.pickedPath = null;
      await state.pickScreenshot();

      expect(state.imagePath, '/first.png');
      expect(state.recognizedText, previousText);
      expect(repository.readCalls, 1);
      expect(state.isBusy, isFalse);
    });

    test('gambar baru menghapus teks lama dan mencegah proses ganda', () async {
      repository.pickedPath = '/first.png';
      await state.pickScreenshot();

      repository.pickedPath = '/second.png';
      final pending = Completer<String>();
      repository.pendingRead = pending;

      final operation = state.pickScreenshot();

      await Future<void>.delayed(Duration.zero);

      expect(state.imagePath, '/second.png');
      expect(state.recognizedText, isEmpty);
      expect(state.phase, ScreenshotPhase.reading);

      await state.pickScreenshot();
      await state.readAgain();
      state.clearScreenshot();

      expect(repository.pickCalls, 2);
      expect(repository.readCalls, 2);
      expect(state.imagePath, '/second.png');

      pending.complete('Ukuran L: dada 104 cm');
      await operation;

      expect(state.recognizedText, 'Ukuran L: dada 104 cm');
      expect(state.isBusy, isFalse);
    });

    test('OCR gagal mempertahankan gambar dan dapat dicoba ulang', () async {
      repository.pickedPath = '/sample.png';
      repository.failReading = true;

      await state.pickScreenshot();

      expect(state.imagePath, '/sample.png');
      expect(state.recognizedText, isEmpty);
      expect(state.errorMessage, contains('Teks belum dapat dibaca'));
      expect(state.isBusy, isFalse);

      repository.failReading = false;
      await state.readAgain();

      expect(state.recognizedText, repository.resultText);
      expect(state.errorMessage, isNull);
      expect(repository.pickCalls, 1);
      expect(repository.readCalls, 2);
    });

    test('OCR tanpa teks menampilkan pesan yang sesuai', () async {
      repository.pickedPath = '/blank.png';
      repository.resultText = '   ';

      await state.pickScreenshot();

      expect(state.imagePath, '/blank.png');
      expect(state.recognizedText, isEmpty);
      expect(state.errorMessage, contains('Teks belum ditemukan'));
      expect(state.isBusy, isFalse);
    });

    test('mengosongkan pilihan membersihkan gambar dan hasil OCR', () async {
      repository.recoveredPath = '/recovered.png';
      await state.initialize();

      state.clearScreenshot();

      expect(state.imagePath, isNull);
      expect(state.recognizedText, isEmpty);
      expect(state.errorMessage, isNull);
      expect(state.noticeMessage, isNull);
    });
  });

  test('hasil galeri diabaikan setelah provider dilepas', () async {
    final repository = FakeScreenshotRepository();
    final pending = Completer<String?>();
    repository.pendingPick = pending;

    final state = ScreenshotProvider(repository);
    final operation = state.pickScreenshot();

    state.dispose();

    pending.complete('/late.png');
    await operation;

    expect(repository.readCalls, 0);
  });
}

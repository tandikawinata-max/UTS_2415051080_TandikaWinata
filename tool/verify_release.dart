import 'dart:convert';
import 'dart:io';
import 'package:usize/config/app_configuration.dart';

/// Jalankan dari akar proyek: dart run tool/verify_release.dart
Future<void> main(List<String> arguments) async {
  var configPath = 'config/local.json';
  var checksOnly = false;
  var offlinePub = false;
  for (final argument in arguments) {
    if (argument == '--checks-only') {
      checksOnly = true;
    } else if (argument == '--offline-pub') {
      offlinePub = true;
    } else if (argument.startsWith('--config=')) {
      configPath = argument.substring('--config='.length);
    } else {
      stderr.writeln(
        'Argumen tidak dikenal. Gunakan --checks-only, --offline-pub, atau --config=path.json.',
      );
      exitCode = 64;
      return;
    }
  }
  if (!File('pubspec.yaml').existsSync() ||
      !Directory('android').existsSync()) {
    stderr.writeln('Jalankan dari folder utama proyek Usize.');
    exitCode = 64;
    return;
  }
  try {
    final data = jsonDecode(await File(configPath).readAsString());
    if (data is! Map<String, dynamic>) throw const FormatException();
    AppConfiguration.fromJson(data).validate();
  } on AppConfigurationException catch (error) {
    stderr.writeln('Konfigurasi belum valid: ${error.message}');
    exitCode = 65;
    return;
  } catch (_) {
    stderr.writeln('File konfigurasi belum dapat dibaca sebagai objek JSON.');
    exitCode = 65;
    return;
  }
  stdout.writeln(
    'Konfigurasi publik valid secara format. Nilainya tidak dicetak.',
  );
  final flutter = Platform.isWindows ? 'flutter.bat' : 'flutter';
  final steps = <(String, List<String>)>[
    (flutter, ['pub', 'get', if (offlinePub) '--offline']),
    (
      Platform.resolvedExecutable,
      [
        'format',
        '--output=none',
        '--set-exit-if-changed',
        'lib',
        'test',
        'tool',
      ],
    ),
    (flutter, ['analyze', '--no-pub']),
    (flutter, ['test', '--no-pub', '--reporter', 'expanded']),
    if (!checksOnly)
      (
        flutter,
        [
          'build',
          'apk',
          '--release',
          '--no-pub',
          '--dart-define-from-file=$configPath',
        ],
      ),
  ];
  for (final (command, args) in steps) {
    stdout.writeln(
      '\nMenjalankan ${command == Platform.resolvedExecutable ? 'dart' : 'flutter'} ${args.first}...',
    );
    try {
      final process = await Process.start(
        command,
        args,
        mode: ProcessStartMode.inheritStdio,
        runInShell: Platform.isWindows,
        environment: {
          'CI': 'true',
          'FLUTTER_SUPPRESS_ANALYTICS': 'true',
          'DASH__SUPPRESS_ANALYTICS': 'true',
        },
      );
      final result = await process.exitCode;
      if (result != 0) {
        stderr.writeln(
          'Pemeriksaan berhenti karena langkah ini gagal. APK lama bukan hasil pemeriksaan ini.',
        );
        exitCode = result;
        return;
      }
    } on ProcessException {
      stderr.writeln(
        'Perintah belum dapat dijalankan. Pastikan Flutter dan Dart tersedia di PATH.',
      );
      exitCode = 1;
      return;
    }
  }
  if (checksOnly) {
    stdout.writeln('Pemeriksaan kode selesai. APK belum dibuat.');
  } else {
    const apkPath = 'build/app/outputs/flutter-apk/app-release.apk';
    final apk = File(apkPath);
    if (!await apk.exists() || await apk.length() == 0) {
      stderr.writeln('Build selesai tetapi APK belum ditemukan.');
      exitCode = 1;
      return;
    }
    stdout.writeln('APK pengujian tersedia: $apkPath');
    stdout.writeln(
      'Lanjutkan checklist perangkat pada docs/testing/tahap16.md.',
    );
  }
}

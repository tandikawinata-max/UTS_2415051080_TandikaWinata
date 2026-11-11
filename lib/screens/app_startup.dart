import 'package:flutter/material.dart';
import '../config/app_configuration.dart';
import '../theme/usize_theme.dart';

class AppStartup extends StatefulWidget {
  final Future<void> Function() initialize;
  final Widget child;
  const AppStartup({super.key, required this.initialize, required this.child});
  @override
  State<AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<AppStartup> {
  late Future<void> _initialization;
  bool _starting = false;
  @override
  void initState() {
    super.initState();
    _initialization = _begin();
  }

  Future<void> _begin() {
    _starting = true;
    return Future.sync(widget.initialize).whenComplete(() {
      _starting = false;
    });
  }

  void _retry() {
    if (_starting) return;
    setState(() {
      _initialization = _begin();
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _initialization,
    builder: (context, snapshot) {
      final finished = snapshot.connectionState == ConnectionState.done;
      final failed = finished && snapshot.hasError;
      if (finished && !failed) return widget.child;
      final configurationError = snapshot.error is AppConfigurationException;
      return MaterialApp(
        title: 'Usize',
        debugShowCheckedModeBanner: false,
        theme: UsizeTheme.light,
        home: Scaffold(
          appBar: AppBar(title: const Text('Usize')),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!failed) ...[
                        const CircularProgressIndicator(),
                        const SizedBox(height: 24),
                        const Text('Membuka Usize...'),
                      ] else ...[
                        const Icon(Icons.info_outline, size: 48),
                        const SizedBox(height: 16),
                        const Text('Usize belum dapat dibuka'),
                        const SizedBox(height: 12),
                        Text(
                          configurationError
                              ? 'Konfigurasi aplikasi belum sesuai. Hubungi penyedia aplikasi untuk mendapatkan versi yang diperbaiki.'
                              : 'Terjadi kendala saat menyiapkan aplikasi. Coba buka kembali.',
                          textAlign: TextAlign.center,
                        ),
                        if (!configurationError) ...[
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            key: const ValueKey('retryStartup'),
                            onPressed: _retry,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Coba lagi'),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

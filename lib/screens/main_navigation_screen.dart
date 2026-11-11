import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/measurement_provider.dart';
import '../providers/screenshot_provider.dart';
import '../providers/size_analysis_provider.dart';
import '../repositories/screenshot_repository.dart';
import 'analysis_history_screen.dart';
import 'dashboard_screen.dart';
import 'ocr_test_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final ScreenshotRepository? screenshotRepository;

  const MainNavigationScreen({super.key, this.screenshotRepository});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late final ScreenshotProvider _screenshotProvider;
  late final SizeAnalysisProvider _analysisProvider;

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    _screenshotProvider = ScreenshotProvider(
      widget.screenshotRepository ?? DeviceScreenshotRepository(),
    );

    _analysisProvider = SizeAnalysisProvider(
      measurements: context.read<MeasurementProvider>(),
      screenshots: _screenshotProvider,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_recoverScreenshot());
      }
    });
  }

  Future<void> _recoverScreenshot() async {
    final recovered = await _screenshotProvider.initialize();

    if (!mounted || !recovered) {
      return;
    }

    _selectTab(1);
  }

  void _selectTab(int index) {
    if (_selectedIndex == index) {
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    _analysisProvider.dispose();
    _screenshotProvider.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ScreenshotProvider>.value(
          value: _screenshotProvider,
        ),
        ChangeNotifierProvider<SizeAnalysisProvider>.value(
          value: _analysisProvider,
        ),
      ],
      child: PopScope<Object?>(
        canPop: _selectedIndex == 0,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && _selectedIndex != 0) {
            _selectTab(0);
          }
        },
        child: Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              DashboardScreen(onOpenAnalysis: () => _selectTab(1)),
              const OcrTestScreen(),
              const AnalysisHistoryScreen(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _selectTab,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Beranda',
              ),
              NavigationDestination(
                icon: Icon(Icons.document_scanner_outlined),
                selectedIcon: Icon(Icons.document_scanner),
                label: 'Analisis',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history),
                label: 'Riwayat',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

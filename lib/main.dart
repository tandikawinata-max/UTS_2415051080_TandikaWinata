import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/measurement_provider.dart';
import 'repositories/demo_measurement_repository.dart';
import 'repositories/measurement_repository.dart';
import 'screens/main_navigation_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  final MeasurementRepository? repository;

  const MyApp({super.key, this.repository});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        return MeasurementProvider(repository ?? DemoMeasurementRepository())
          ..loadMeasurements();
      },
      child: MaterialApp(
        title: 'Usize',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          scaffoldBackgroundColor: const Color(0xFFF7F8FC),
          useMaterial3: true,
        ),
        home: const MainNavigationScreen(),
      ),
    );
  }
}

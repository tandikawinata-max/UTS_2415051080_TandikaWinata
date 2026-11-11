import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/measurement_provider.dart';
import 'repositories/analysis_history_repository.dart';
import 'repositories/demo_analysis_history_repository.dart';
import 'repositories/supabase_analysis_history_repository.dart';
import 'services/analysis_history_service.dart';
import 'theme/usize_theme.dart';
import 'providers/session_provider.dart';
import 'repositories/measurement_repository.dart';
import 'repositories/session_repository.dart';
import 'repositories/supabase_measurement_repository.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'services/measurement_service.dart';
import 'services/session_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    publishableKey: const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  // Repository dapat disuntikkan oleh pengujian.
  final MeasurementRepository? repository;
  final AnalysisHistoryRepository? historyRepository;

  const MyApp({super.key, this.repository, this.historyRepository});

  @override
  Widget build(BuildContext context) {
    if (repository != null) {
      return _ProfileApp(
        repository: repository!,
        historyRepository: historyRepository ?? DemoAnalysisHistoryRepository(),
      );
    }

    final client = Supabase.instance.client;

    return ChangeNotifierProvider(
      create: (_) =>
          SessionProvider(SupabaseSessionRepository(SessionService(client))),
      child: const _SessionApp(),
    );
  }
}

class _SessionApp extends StatelessWidget {
  const _SessionApp();

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<SessionProvider>().userId;

    if (userId == null) {
      return const _UsizeMaterialApp(
        key: ValueKey('login'),
        home: LoginScreen(),
      );
    }

    return _ProfileApp(
      key: ValueKey(userId),
      historyRepository: SupabaseAnalysisHistoryRepository(
        AnalysisHistoryService(Supabase.instance.client, userId),
      ),
      repository: SupabaseMeasurementRepository(
        MeasurementService(Supabase.instance.client, userId),
      ),
    );
  }
}

class _ProfileApp extends StatelessWidget {
  final MeasurementRepository repository;
  final AnalysisHistoryRepository historyRepository;

  const _ProfileApp({
    super.key,
    required this.repository,
    required this.historyRepository,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MeasurementProvider(repository)..loadMeasurements(),
      child: _UsizeMaterialApp(
        home: MainNavigationScreen(historyRepository: historyRepository),
      ),
    );
  }
}

class _UsizeMaterialApp extends StatelessWidget {
  final Widget home;

  const _UsizeMaterialApp({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Usize',
      debugShowCheckedModeBanner: false,
      theme: UsizeTheme.light,
      home: home,
    );
  }
}

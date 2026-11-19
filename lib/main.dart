import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_keys.dart';
import 'firebase_options.dart';
import 'providers/course_provider.dart';
import 'repositories/course_repository.dart';
import 'screens/login_page.dart';
import 'screens/main_dashboard.dart';
import 'services/auth_service.dart';
import 'services/course_supabase_service.dart';

// Identitas Mahasiswa
const String studentName = 'Tandika Winata';
const String studentId = '2415051080';

// Konfigurasi Supabase
const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://brvrwwnybauemcmxwoff.supabase.co',
);

const String supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
  defaultValue: 'sb_publishable_9wsf43wmi4_SNTNOrmqqaA_8nZgnBya',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase (Praktik 7)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Firebase berhasil diinisialisasi');

  if (supabaseUrl.isEmpty || supabasePublishableKey.isEmpty) {
    throw StateError(
      'Konfigurasi Supabase belum tersedia. '
      'Periksa SUPABASE_URL dan '
      'SUPABASE_PUBLISHABLE_KEY.',
    );
  }

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );

  // Mendengarkan perubahan status autentikasi (otomatis redirect jika signedOut)
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    debugPrint('Auth event: ${data.event}');
    if (data.event == AuthChangeEvent.signedOut) {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  });

  debugPrint('Supabase client berhasil diinisialisasi');
  debugPrint('Mahasiswa: $studentName ($studentId)');

  // Menggunakan CourseSupabaseService agar terhubung ke database Supabase
  final repository = CourseRepository(CourseSupabaseService());

  runApp(
    ChangeNotifierProvider(
      create: (_) => CourseProvider(repository)..loadCourses(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Course Explorer v2',
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: messengerKey,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)),
      ),
      // Check Session: jika sudah login langsung ke MainDashboard, jika belum ke LoginPage
      home: AuthService.instance.isLoggedIn
          ? const MainDashboard()
          : const LoginPage(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/course_provider.dart';
import 'repositories/course_repository.dart';
import 'screens/login_page.dart';
import 'services/course_api.dart';

// Identitas Mahasiswa
const String studentName = 'Tandika Winata';
const String studentId = '2415051080';

// Konfigurasi Supabase (fallback ke string langsung jika tidak pakai --dart-define)
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

  // Memeriksa konfigurasi Supabase
  if (supabaseUrl.isEmpty || supabasePublishableKey.isEmpty) {
    throw StateError(
      'Konfigurasi Supabase belum tersedia. '
      'Periksa SUPABASE_URL dan '
      'SUPABASE_PUBLISHABLE_KEY.',
    );
  }

  // Inisialisasi Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );

  debugPrint('Supabase client berhasil diinisialisasi');
  debugPrint('Mahasiswa: $studentName ($studentId)');

  // Inisialisasi Repository dari project sebelumnya
  final repository = CourseRepository(
    CourseApiService('https://course-api-pearl.vercel.app/endpoint-salah'),
  );

  // Membungkus MyApp dengan CourseProvider
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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)),
      ),
      home: const LoginPage(),
    );
  }
}

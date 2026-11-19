import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../app_keys.dart';
import '../firebase_options.dart';

// Top-level function wajib untuk menangani pesan saat aplikasi di background/terminated
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('=== [BACKGROUND FCM] ===');
  debugPrint('Message ID: ${message.messageId}');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
}

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> init() async {
    // 1. Minta izin notifikasi (Praktik 8)
    final NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('Status izin notifikasi: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      final String? token = await _messaging.getToken();
      debugPrint('FCM Device Token: $token');
    } else {
      debugPrint('Izin notifikasi ditolak oleh pengguna.');
      return;
    }

    // 2. Tangani pesan saat aplikasi sedang dibuka (FOREGROUND)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.notification?.title ?? 'Notifikasi Baru';
      final body = message.notification?.body ?? '';

      debugPrint('=== [FOREGROUND FCM] ===');
      debugPrint('Title: $title | Body: $body');

      messengerKey.currentState?.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (body.isNotEmpty) Text(body),
            ],
          ),
        ),
      );
    });

    // 3. Tangani ketika pengguna mengetuk notifikasi dari tray (BACKGROUND -> OPENED)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('=== [NOTIFIKASI DIKETUK] ===');
      debugPrint('Title: ${message.notification?.title}');
      debugPrint('Data payload: ${message.data}');
    });

    // 4. Cek apakah aplikasi dibuka dari kondisi mati total (TERMINATED) lewat notifikasi
    final RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('=== [DIBUKA DARI TERMINATED] ===');
      debugPrint('Title: ${initialMessage.notification?.title}');
    }
  }
}

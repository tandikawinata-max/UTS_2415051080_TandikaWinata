import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initPermission() async {
    // 1. Meminta izin notifikasi ke sistem OS (Android 13+ / iOS)
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

    // 2. Jika diizinkan, ambil FCM Token perangkat
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      final String? token = await _messaging.getToken();
      debugPrint('FCM Device Token: $token');
    } else {
      debugPrint('Izin notifikasi ditolak oleh pengguna.');
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ── Local notifications (works without Firebase) ──────────────────────────
// To add Firebase FCM later:
//   1. flutter pub add firebase_core firebase_messaging
//   2. Add google-services.json to android/app/
//   3. Apply google-services plugin in android/app/build.gradle.kts
//   4. Uncomment the Firebase sections below and call _setupFCM()

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'bloodconnect_alerts';
  static const _channelName = 'BloodConnect Alerts';

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onTap,
    );
    await _createChannel();
  }

  static Future<void> _createChannel() async {
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Blood shortage and donation alerts',
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static void _onTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  static Future<void> showShortageAlert({
    required String bloodType,
    required String centerName,
  }) =>
      _show(
        id: bloodType.hashCode,
        title: '🩸 Critical shortage: $bloodType',
        body: '$centerName urgently needs $bloodType donors',
      );

  static Future<void> showAppointmentUpdate({
    required String status,
    required String centerName,
  }) {
    final emoji = switch (status) {
      'confirmed' => '✅',
      'rejected' => '❌',
      'completed' => '🎉',
      _ => '📋',
    };
    return _show(
      id: status.hashCode,
      title: '$emoji Appointment $status',
      body: 'Your appointment at $centerName has been $status',
    );
  }

  static Future<void> _show({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(id: id, title: title, body: body, notificationDetails: details);
  }

  // ── FCM code (uncomment after Firebase setup) ────────────────────────────
  // static Future<void> _setupFCM() async {
  //   final messaging = FirebaseMessaging.instance;
  //   await messaging.requestPermission(alert: true, badge: true, sound: true);
  //   final token = await messaging.getToken();
  //   debugPrint('FCM Token: $token');
  //   // Send token to backend: PATCH /users/me { fcmToken: token }
  //   FirebaseMessaging.onMessage.listen((msg) {
  //     _show(
  //       id: msg.hashCode,
  //       title: msg.notification?.title ?? 'BloodConnect',
  //       body: msg.notification?.body ?? '',
  //     );
  //   });
  // }
}

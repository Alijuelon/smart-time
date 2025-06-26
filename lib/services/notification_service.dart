import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../main.dart';

Future<void> initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      // Handle notification taps
      if (response.payload != null) {
        // Navigate to specific screen if needed
      }
    },
  );
}

Future<void> requestNotificationPermission() async {
  final plugin = flutterLocalNotificationsPlugin;
  final androidImplementation =
      plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
  await androidImplementation?.requestPermission();
}

Future<void> scheduleRuleNotification({
  required int id,
  required String title,
  required Duration duration,
}) async {
  final scheduledTime = tz.TZDateTime.now(tz.local).add(duration);

  final androidDetails = const AndroidNotificationDetails(
    'rule_channel',
    'Aturan',
    channelDescription: 'Notifikasi saat aturan habis',
    importance: Importance.max,
    priority: Priority.high,
    sound: RawResourceAndroidNotificationSound('notification'),
    enableLights: true,
    color: Color(0xFF4E67EB),
    ledColor: Color(0xFF4E67EB),
    ledOnMs: 1000,
    ledOffMs: 500,
    playSound: true,
    styleInformation: BigTextStyleInformation(''),
    visibility: NotificationVisibility.public,
    ticker: 'Smart Time notification',
  );

  await flutterLocalNotificationsPlugin.zonedSchedule(
    id,
    'Waktu Habis!',
    'Aturan "$title" sudah berakhir.',
    scheduledTime,
    NotificationDetails(android: androidDetails),
    androidAllowWhileIdle: true,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    // Tidak perlu pakai matchDateTimeComponents
  );
}

Future<void> schedulePreEndNotification({
  required int id,
  required String title,
  required Duration duration,
}) async {
  final scheduledTime = tz.TZDateTime.now(
    tz.local,
  ).add(duration).subtract(const Duration(minutes: 1));

  final androidDetails = const AndroidNotificationDetails(
    'pre_end_channel',
    'Peringatan Hampir Habis',
    channelDescription: 'Notifikasi 1 menit sebelum aturan habis',
    importance: Importance.max,
    priority: Priority.high,
    sound: RawResourceAndroidNotificationSound('notification'),
    enableLights: true,
    color: Color(0xFF4E67EB),
    ledColor: Color(0xFF4E67EB),
    ledOnMs: 1000,
    ledOffMs: 500,
    playSound: true,
    styleInformation: BigTextStyleInformation(''),
    visibility: NotificationVisibility.public,
    ticker: 'Smart Time warning notification',
  );

  await flutterLocalNotificationsPlugin.zonedSchedule(
    id,
    'Hampir Habis!',
    'Aturan "$title" tinggal 1 menit lagi.',
    scheduledTime,
    NotificationDetails(android: androidDetails),
    androidAllowWhileIdle: true,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    // Tidak perlu pakai matchDateTimeComponents
  );
}

Future<void> showViolationNotification(String ruleName) async {
  final androidDetails = const AndroidNotificationDetails(
    'violation_channel',
    'Pelanggaran',
    channelDescription: 'Notifikasi saat aturan dilanggar',
    importance: Importance.max,
    priority: Priority.high,
    sound: RawResourceAndroidNotificationSound('notification'),
    enableLights: true,
    color: Colors.red,
    ledColor: Colors.red,
    ledOnMs: 1000,
    ledOffMs: 500,
    playSound: true,
    styleInformation: BigTextStyleInformation(''),
    visibility: NotificationVisibility.public,
    ticker: 'Smart Time violation notification',
  );

  await flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    'Aturan Dilanggar!',
    'Aturan "$ruleName" telah habis waktunya dan belum selesai.',
    NotificationDetails(android: androidDetails),
  );
}

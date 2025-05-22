import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
    );
    await _plugin.initialize(initSettings);
  }

  Future<void> scheduleNotification(
    DateTime date,
    String title,
    String body,
    int id,
  ) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'remotes',
        'Trabajo Remoto',
        channelDescription: 'Notificaciones de rotacion',
      ),
    );
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      date.toUtc(),
      details,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}

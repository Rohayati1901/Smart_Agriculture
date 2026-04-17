import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _notif = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _notif.initialize(settings);
  }

  static Future<void> showDrySoil() async {
    await _notif.show(
      0,
      'Peringatan!',
      'Tanah terlalu kering, segera siram!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'soil_channel',
          'Soil Alert',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
}
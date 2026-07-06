import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  
  static Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(settings: initSettings);
  }

  static Future<void> showBreachNotification(String appLabel) async {
    const androidDetails = AndroidNotificationDetails(
      'breach_channel',
      'Breach Alerts',
      channelDescription: 'Notifications for app limits exceeded',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    const details = NotificationDetails(android: androidDetails);
    
    await _plugin.show(
      id: DateTime.now().millisecond, // Random unique ID
      title: 'DoomScroll Alert',
      body: 'You have exceeded your limit for $appLabel for today.',
      notificationDetails: details,
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _mainChannelId = 'guardx_main';
  static const String _sosChannelId = 'guardx_sos';
  static const String _tripChannelId = 'guardx_trip';

  // ── Init ─────────────────────────────────────
  static Future<void> init() async {
    // flutter_local_notifications not supported on web
    if (kIsWeb) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Request Android 13+ permission
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  // ── FIXED: Positional params for title + body ──
  static Future<void> show(
    String title,  // ← positional (was named required)
    String body,   // ← positional (was named required)
    {
    int id = 0,
    String channelId = _mainChannelId,
    String channelName = 'Guard-X Alerts',
    Importance importance = Importance.high,
    Priority priority = Priority.high,
  }) async {
    if (kIsWeb) return; // Not supported on web

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Safety alerts from Guard-X',
      importance: importance,
      priority: priority,
      playSound: true,
      enableVibration: true,
      ticker: 'Guard-X Alert',
      styleInformation: BigTextStyleInformation(body),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(id, title, body, details);
  }

  // ── Specific Helpers ───────────────────────────
  static Future<void> showTripStarted(String destination) async {
    await show(
      '🗺️ Trip Started',
      'Monitoring your journey to $destination. Stay safe!',
      id: 1,
      channelId: _tripChannelId,
      channelName: 'Trip Alerts',
    );
  }

  static Future<void> showTripCompleted(String destination) async {
    await show(
      '✅ Arrived Safely!',
      'You reached $destination safely. Trip monitoring ended.',
      id: 2,
      channelId: _tripChannelId,
      channelName: 'Trip Alerts',
    );
  }

  static Future<void> showSafetyCheck() async {
    await show(
      '⚠️ Are You Safe?',
      'Your trip timer has expired. Please confirm your safety!',
      id: 3,
      channelId: _sosChannelId,
      channelName: 'SOS Alerts',
      importance: Importance.max,
      priority: Priority.max,
    );
  }

  static Future<void> showSOSTriggered() async {
    await show(
      '🚨 SOS Activated',
      'Emergency alert sent! Contacting your guardians now.',
      id: 4,
      channelId: _sosChannelId,
      channelName: 'SOS Alerts',
      importance: Importance.max,
      priority: Priority.max,
    );
  }

  static Future<void> cancel(int id) async {
    if (kIsWeb) return;
    await _plugin.cancel(id);
  }

  static Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }
}
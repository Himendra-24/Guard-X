import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  // ── Request All App Permissions ─────────────────
  static Future<void> requestAll() async {
    if (kIsWeb) return;

    await _requestPhone();
    await _requestSMS();
    await _requestNotification();
    await _requestLocation();
  }

  // ── Phone Call Permission ───────────────────────
  static Future<bool> _requestPhone() async {
    final status = await Permission.phone.request();
    debugPrint('📞 Phone permission: $status');
    return status.isGranted;
  }

  // ── SMS Permission ──────────────────────────────
  static Future<bool> _requestSMS() async {
    final status = await Permission.sms.request();
    debugPrint('💬 SMS permission: $status');
    return status.isGranted;
  }

  // ── Notification Permission (Android 13+) ───────
  static Future<bool> _requestNotification() async {
    final status = await Permission.notification.request();
    debugPrint('🔔 Notification permission: $status');
    return status.isGranted;
  }

  // ── Location Permission ─────────────────────────
  static Future<bool> _requestLocation() async {
    final status = await Permission.location.request();
    debugPrint('📍 Location permission: $status');
    return status.isGranted;
  }

  // ── Check Individual Permissions ────────────────
  static Future<bool> hasPhonePermission() async {
    if (kIsWeb) return false;
    return await Permission.phone.isGranted;
  }

  static Future<bool> hasSMSPermission() async {
    if (kIsWeb) return false;
    return await Permission.sms.isGranted;
  }

  static Future<bool> hasNotificationPermission() async {
    if (kIsWeb) return false;
    return await Permission.notification.isGranted;
  }

  static Future<bool> hasLocationPermission() async {
    if (kIsWeb) return false;
    return await Permission.location.isGranted;
  }

  // ── Check + Request Before Action ──────────────
  static Future<bool> ensurePhonePermission() async {
    if (kIsWeb) return false;
    if (await Permission.phone.isGranted) return true;
    final status = await Permission.phone.request();
    return status.isGranted;
  }

  static Future<bool> ensureSMSPermission() async {
    if (kIsWeb) return false;
    if (await Permission.sms.isGranted) return true;
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  static Future<bool> ensureLocationPermission() async {
    if (kIsWeb) return false;
    if (await Permission.location.isGranted) return true;
    final status = await Permission.location.request();
    return status.isGranted;
  }

  // ── Get All Statuses (for debug/settings screen) ─
  static Future<Map<String, String>> getAllStatuses() async {
    if (kIsWeb) {
      return {
        'Phone': 'Not available on web',
        'SMS': 'Not available on web',
        'Notification': 'Not available on web',
        'Location': 'Not available on web',
      };
    }

    final phone = await Permission.phone.status;
    final sms = await Permission.sms.status;
    final notification = await Permission.notification.status;
    final location = await Permission.location.status;

    return {
      'Phone': _statusLabel(phone),
      'SMS': _statusLabel(sms),
      'Notification': _statusLabel(notification),
      'Location': _statusLabel(location),
    };
  }

  static String _statusLabel(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return '✅ Granted';
      case PermissionStatus.denied:
        return '❌ Denied';
      case PermissionStatus.permanentlyDenied:
        return '🚫 Permanently Denied';
      case PermissionStatus.restricted:
        return '⛔ Restricted';
      case PermissionStatus.limited:
        return '⚠️ Limited';
      default:
        return '❓ Unknown';
    }
  }

  // ── Open App Settings (if permanently denied) ───
  static Future<void> openSettings() async {
    await openAppSettings();
  }
}
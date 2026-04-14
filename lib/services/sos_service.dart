import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/contact.dart';
import 'permission_service.dart';

class SOSService {
  // ── Call Contact ─────────────────────────────────
  static Future<bool> callContact(Contact contact) async {
    if (kIsWeb) {
      debugPrint('Calling not supported on web');
      return false;
    }

    final hasPermission = await PermissionService.ensurePhonePermission();
    if (!hasPermission) {
      debugPrint('❌ Phone permission denied');
      return false;
    }

    final phone = _sanitizePhone(contact.phone);
    final uri = Uri(scheme: 'tel', path: phone);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      }
    } catch (e) {
      debugPrint('Error launching call: $e');
    }
    return false;
  }

  // ── Send SMS ─────────────────────────────────────
  static Future<bool> sendSMS(Contact contact, String message) async {
    if (kIsWeb) {
      debugPrint('SMS not supported on web');
      return false;
    }

    final hasPermission = await PermissionService.ensureSMSPermission();
    if (!hasPermission) {
      debugPrint('❌ SMS permission denied');
      return false;
    }

    final phone = _sanitizePhone(contact.phone);
    final encoded = Uri.encodeComponent(message);
    final uri = Uri.parse('sms:$phone?body=$encoded');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      }
    } catch (e) {
      debugPrint('Error launching SMS: $e');
    }
    return false;
  }

  // ── Send SOS to All Contacts ──────────────────────
  static Future<void> sendSOSToAll(
    List<Contact> contacts, {
    String? customMessage,
    double? lat,
    double? lng,
  }) async {
    final message = customMessage ??
        buildSOSMessage(location: _buildLocationString(lat, lng));

    for (final contact in contacts) {
      final success = await sendSMS(contact, message);
      debugPrint(success
          ? '✅ SMS sent to ${contact.name}'
          : '❌ SMS failed for ${contact.name}');
      await Future.delayed(const Duration(milliseconds: 600));
    }
  }

  // ── Open URL ──────────────────────────────────────
  static Future<bool> openUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (e) {
      debugPrint('Error opening URL: $e');
    }
    return false;
  }

  // ── Build SOS Message ─────────────────────────────
  static String buildSOSMessage({String? name, String? location}) {
    final buffer = StringBuffer();
    buffer.writeln('🚨 EMERGENCY SOS — Guard-X Safety App');
    buffer.writeln('');
    if (name != null) buffer.writeln('Person: $name');
    if (location != null && location.isNotEmpty) {
      buffer.writeln('Location: $location');
    }
    buffer.writeln('');
    buffer.writeln('Please respond immediately or call emergency services.');
    return buffer.toString();
  }

  // ── Build Location String ─────────────────────────
  static String? _buildLocationString(double? lat, double? lng) {
    if (lat == null || lng == null) return null;
    return 'https://maps.google.com/?q=$lat,$lng';
  }

  // ── Get Primary Contact ───────────────────────────
  static Contact? getPrimaryContact(List<Contact> contacts) {
    if (contacts.isEmpty) return null;
    try {
      return contacts.firstWhere((c) => c.isPrimary);
    } catch (_) {
      return contacts.first; // Fallback to first contact
    }
  }

  // ── Sanitize Phone ────────────────────────────────
  static String _sanitizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  }
}
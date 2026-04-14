import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/contact.dart';
import 'permission_service.dart';

class LocationService {
  static Position? _lastPosition;

  /// Get current GPS location
  static Future<Position?> getCurrentLocation() async {
    if (kIsWeb) return null;

    try {
      final hasPermission = await PermissionService.ensureLocationPermission();
      if (!hasPermission) {
        debugPrint('❌ Location permission denied');
        return null;
      }

      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('❌ Location services disabled');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      _lastPosition = position;
      debugPrint('📍 Location: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      debugPrint('❌ Location error: $e');
      return null;
    }
  }

  /// Get last known position (fast, offline-friendly)
  static Position? get lastPosition => _lastPosition;

  /// Build Google Maps link from coordinates
  static String buildMapsLink(double lat, double lng) {
    return 'https://maps.google.com/?q=$lat,$lng';
  }

  /// Build a trip-start SMS message with location
  static String buildTripMessage({
    required String destination,
    double? lat,
    double? lng,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('🗺️ Guard-X Trip Alert');
    buffer.writeln('I started a trip to $destination.');
    if (lat != null && lng != null) {
      buffer.writeln('My location: ${buildMapsLink(lat, lng)}');
    }
    buffer.writeln('I\'ll confirm when I arrive safely.');
    return buffer.toString();
  }

  /// Open SMS app with pre-filled location message
  static Future<bool> shareLocationViaSMS(
    Contact contact, {
    required String destination,
    double? lat,
    double? lng,
  }) async {
    if (kIsWeb) return false;

    final message = buildTripMessage(
      destination: destination,
      lat: lat,
      lng: lng,
    );

    final phone = contact.phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final encoded = Uri.encodeComponent(message);
    final uri = Uri.parse('sms:$phone?body=$encoded');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      }
    } catch (e) {
      debugPrint('❌ SMS launch error: $e');
    }
    return false;
  }
}

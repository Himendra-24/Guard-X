import 'dart:async';
import 'package:flutter/foundation.dart';
import 'alert_service.dart';
import 'notification_service.dart';

/// 3-stage automated safety engine for trip monitoring.
///
/// Stage 1: Timer expires → callback (show "Are you safe?" popup)
/// Stage 2: After [stage2Delay] → callback (alarm + vibration)
/// Stage 3: After [stage3Delay] → callback (open SOS screen)
class TripMonitorService {
  static Timer? _stage2Timer;
  static Timer? _stage3Timer;
  static int _currentStage = 0;
  static bool _isActive = false;

  /// Delays between stages (configurable)
  static const Duration stage2Delay = Duration(seconds: 30);
  static const Duration stage3Delay = Duration(seconds: 30);

  static bool get isActive => _isActive;
  static int get currentStage => _currentStage;

  /// Called when the trip timer expires. Triggers Stage 1.
  ///
  /// [onStage1] — show "Are you safe?" popup
  /// [onStage2] — trigger alarm + vibration
  /// [onStage3] — open SOS screen automatically
  static void startSafetyCheck({
    required VoidCallback onStage1,
    required VoidCallback onStage2,
    required VoidCallback onStage3,
  }) {
    if (_isActive) return;
    _isActive = true;
    _currentStage = 1;

    debugPrint('🛡️ Safety Check — Stage 1: Are you safe?');
    NotificationService.showSafetyCheck();
    onStage1();

    // Stage 2: after delay, trigger alarm + vibration
    _stage2Timer = Timer(stage2Delay, () {
      if (!_isActive) return;
      _currentStage = 2;
      debugPrint('🛡️ [TripMonitor] Safety Check EXPIRED — Stage 2: Triggering Alarm + Vibration');
      AlertService.playAlarm();
      AlertService.emergencyVibrate();
      NotificationService.show(
        '🚨 No Response!',
        'You haven\'t responded to the safety check. Alarm activated!',
        id: 5,
      );
      onStage2();

      // Stage 3: after another delay, open SOS
      _stage3Timer = Timer(stage3Delay, () {
        if (!_isActive) return;
        _currentStage = 3;
        debugPrint('🛡️ Safety Check — Stage 3: SOS Activated');
        NotificationService.show(
          '🚨 SOS AUTO-TRIGGERED',
          'No response received. Emergency SOS has been activated.',
          id: 6,
        );
        onStage3();
      });
    });
  }

  /// Cancel the safety check (user confirmed safe)
  static Future<void> cancel() async {
    _stage2Timer?.cancel();
    _stage3Timer?.cancel();
    _stage2Timer = null;
    _stage3Timer = null;
    _isActive = false;
    _currentStage = 0;
    await AlertService.stopAlarm();
    debugPrint('✅ Safety check cancelled — user confirmed safe');
  }

  /// Reset everything
  static Future<void> reset() async {
    await cancel();
  }
}

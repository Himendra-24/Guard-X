import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:torch_light/torch_light.dart';
import 'package:vibration/vibration.dart';

class AlertService {
  static AudioPlayer? _persistentPlayer;
  static bool _isLoading = false;
  static bool _isAlarmPlaying = false;

  /// Private common player instance for better resource management
  static AudioPlayer _getPlayer() {
    _persistentPlayer ??= AudioPlayer();
    return _persistentPlayer!;
  }

  // Use high-quality police_siren.wav (relative path for AssetSource)
  static const String _alarmAsset = 'police_siren.wav';

  /// Initialize Audio Context for better hardware support
  static Future<void> _initAudio() async {
    if (kIsWeb) return;
    try {
      final AudioContext audioContext = AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {
            AVAudioSessionOptions.duckOthers,
            AVAudioSessionOptions.defaultToSpeaker,
          },
        ),
        android: AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media, // Changed from alarm to media for stability
          audioFocus: AndroidAudioFocus.gainTransient,
        ),
      );
      AudioPlayer.global.setAudioContext(audioContext);
      debugPrint('🛡️ [AlertService] Audio Context initialized as MEDIA');
    } catch (e) {
      debugPrint('❌ [AlertService] Audio context error: $e');
    }
  }

  /// Play alarm sound (looping) for emergencies
  static Future<void> playAlarm() async {
    if (_isAlarmPlaying || _isLoading) return;
    _isLoading = true;
    try {
      await _initAudio();
      final player = _getPlayer();
      
      // Pre-set release mode and volume
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(1.0);

      // Using the standard Method call for best hardware compatibility
      await player.setSource(AssetSource(_alarmAsset));
      
      // Start playback
      await player.resume();
      
      _isAlarmPlaying = true;
      debugPrint('🚨 [AlertService] ALARM_PLAYING: $_alarmAsset');
    } catch (e) {
      debugPrint('❌ [AlertService] ALARM_ERROR: $e');
    } finally {
      _isLoading = false;
    }
  }

  /// Stop alarm sound
  static Future<void> stopAlarm() async {
    try {
      await _persistentPlayer?.stop();
      await Vibration.cancel(); // Kill any looping vibration immediately
      _isAlarmPlaying = false;
      debugPrint('🔇 [AlertService] ALARM_STOPPED');
    } catch (e) {
      debugPrint('❌ [AlertService] Stop error: $e');
    }
  }

  /// Check if alarm is currently playing
  static bool get isAlarmPlaying => _isAlarmPlaying;

  /// Play siren sound (looping) for toolkit
  static Future<void> playSiren() async => playAlarm(); 

  /// Stop siren sound
  static Future<void> stopSiren() async => stopAlarm();

  /// Check if siren is currently playing
  static bool get isSirenPlaying => _isAlarmPlaying;

  /// Toggle hardware flashlight
  static Future<void> toggleFlashlight(bool isOn) async {
    if (kIsWeb) return;
    try {
      if (isOn) {
        await TorchLight.enableTorch();
        debugPrint('🔦 [AlertService] Flashlight ON');
      } else {
        await TorchLight.disableTorch();
        debugPrint('🔦 [AlertService] Flashlight OFF');
      }
    } catch (e) {
      debugPrint('❌ [AlertService] Flashlight Error: $e');
    }
  }

  /// Trigger device vibration pattern
  static Future<void> vibrate() async {
    if (kIsWeb) return;
    try {
      if (await Vibration.hasVibrator() ?? false) {
        await Vibration.vibrate(duration: 500);
      } else {
        await HapticFeedback.mediumImpact();
      }
      debugPrint('📳 [AlertService] Vibration triggered');
    } catch (e) {
      debugPrint('❌ [AlertService] Vibration error: $e');
    }
  }

  /// Trigger sustained vibration pattern (for emergencies)
  static Future<void> emergencyVibrate() async {
    if (kIsWeb) return;
    try {
      if (await Vibration.hasVibrator() ?? false) {
        // Strong emergency pattern
        await Vibration.vibrate(
          pattern: [0, 500, 200, 500, 200, 500],
          repeat: 0, // Loop indefinitely until stopped
        );
        debugPrint('📳 [AlertService] Strong looping vibration triggered');
      } else {
        for (int i = 0; i < 5; i++) {
          await HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }
    } catch (e) {
      debugPrint('❌ [AlertService] Emergency Vibration error: $e');
    }
  }

  /// Stop all alerts
  static Future<void> stopAll() async {
    await stopAlarm();
    await Vibration.cancel();
    try {
      if (!kIsWeb) await TorchLight.disableTorch();
    } catch (_) {}
  }

  /// Dispose players
  static Future<void> dispose() async {
    await _persistentPlayer?.dispose();
    _persistentPlayer = null;
  }
}

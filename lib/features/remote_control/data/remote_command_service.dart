import 'dart:io';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Service for handling remote commands from Windows PC
/// Uses system sounds and vibration package
class RemoteCommandService {
  static const _methodChannel = MethodChannel('com.velocitylink.intune/commands');
  bool _isRinging = false;

  /// Handle incoming remote command
  Future<void> handleCommand(String action) async {
    print('🎯 Handling remote command: $action');
    
    switch (action.toUpperCase()) {
      case 'RING':
        await _ringDevice();
        break;
      case 'STOP_RING':
        await _stopRinging();
        break;
      case 'FLASH':
        await _flashScreen();
        break;
      case 'VIBRATE':
        await _vibrateDevice();
        break;
      default:
        print('⚠️ Unknown command: $action');
    }
  }

  /// Play system notification sound and vibrate
  Future<void> _ringDevice() async {
    if (_isRinging) return;
    _isRinging = true;
    
    try {
      // Vibrate intensively on Android
      if (Platform.isAndroid) {
        final hasVibrator = await Vibration.hasVibrator() ?? false;
        if (hasVibrator) {
          // Create a ringing pattern
          Vibration.vibrate(
            pattern: [500, 1000, 500, 1000, 500, 1000, 500, 1000, 500, 1000],
            intensities: [255, 0, 255, 0, 255, 0, 255, 0, 255, 0],
          );
        }
        
        // Try platform channel for audio
        try {
          await _methodChannel.invokeMethod('ringDevice');
        } catch (e) {
          // Fallback to system sound
          await SystemSound.play(SystemSoundType.alert);
        }
      }
      
      print('🔔 Device is ringing!');
      
      // Auto-stop after 15 seconds
      Future.delayed(const Duration(seconds: 15), () {
        _stopRinging();
      });
    } catch (e) {
      print('❌ Error ringing device: $e');
      await SystemSound.play(SystemSoundType.alert);
      _isRinging = false;
    }
  }

  /// Stop the ringing
  Future<void> _stopRinging() async {
    _isRinging = false;
    try {
      Vibration.cancel();
      await _methodChannel.invokeMethod('stopRing');
    } catch (e) {
      print('❌ Error stopping ring: $e');
    }
    print('🔕 Ring stopped');
  }

  /// Flash the screen with haptic feedback
  Future<void> _flashScreen() async {
    try {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 200));
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 200));
      await HapticFeedback.heavyImpact();
    } catch (e) {
      print('❌ Error with haptic: $e');
    }
    
    print('⚡ Flash triggered');
  }

  /// Strong vibration
  Future<void> _vibrateDevice() async {
    try {
      if (Platform.isAndroid) {
        final hasVibrator = await Vibration.hasVibrator() ?? false;
        if (hasVibrator) {
          Vibration.vibrate(duration: 1000, amplitude: 255);
        }
      } else {
        await HapticFeedback.vibrate();
      }
    } catch (e) {
      print('❌ Error vibrating: $e');
    }
    print('📳 Vibration triggered');
  }

  /// Cleanup
  void dispose() {
    _stopRinging();
  }
}

import 'package:flutter/services.dart';

class AccessibilityChannel {
  static const MethodChannel _channel = MethodChannel('com.velocitylink.intune/accessibility');
  
  /// Check if accessibility service is enabled
  static Future<bool> isServiceEnabled() async {
    try {
      return await _channel.invokeMethod('isServiceEnabled') ?? false;
    } catch (e) {
      print('❌ Error checking accessibility service: $e');
      return false;
    }
  }
  
  /// Open accessibility settings
  static Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openSettings');
    } catch (e) {
      print('❌ Error opening settings: $e');
    }
  }
  
  /// Perform a tap at specific coordinates
  static Future<bool> performTap(double x, double y) async {
    try {
      return await _channel.invokeMethod('tap', {
        'x': x,
        'y': y,
      }) ?? false;
    } catch (e) {
      print('❌ Error performing tap: $e');
      return false;
    }
  }
  
  /// Perform a swipe
  static Future<bool> performSwipe(
    double startX, double startY, 
    double endX, double endY,
    {int duration = 300}
  ) async {
    try {
      return await _channel.invokeMethod('swipe', {
        'startX': startX,
        'startY': startY,
        'endX': endX,
        'endY': endY,
        'duration': duration,
      }) ?? false;
    } catch (e) {
      print('❌ Error performing swipe: $e');
      return false;
    }
  }
  
  /// Perform a back action (global action)
  static Future<bool> performGlobalAction(String action) async {
    try {
      return await _channel.invokeMethod('performGlobalAction', {
        'action': action,
      }) ?? false;
    } catch (e) {
      return false;
    }
  }
}

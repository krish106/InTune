class AppConstants {
  static const String appName = 'VelocityLink';
  static const String appVersion = '1.0.0';
  
  // Device Settings
  static const String deviceIdKey = 'device_id';
  static const String deviceNameKey = 'device_name';
  
  // Feature Flags
  static const bool enableFileTransfer = true;
  static const bool enableClipboard = true;
  static const bool enableScreenShare = true;
  
  // Screen Share Settings (Phase 3)
  static const int targetFPS = 20;
  static const int jpegQuality = 75;
  static const int maxLatencyMs = 250;
}

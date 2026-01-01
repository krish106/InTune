class NetworkConstants {
  // Server Configuration
  static const int defaultPort = 8889;  // Changed from 8888 to avoid conflicts
  static const String wsPath = '/ws';
  
  // Hotspot Detection
  static const List<String> hotspotIPPrefixes = [
    '192.168.137.',  // Windows default
    '192.168.173.',  // Windows alternate
  ];
  
  static const List<String> hotspotAdapterKeywords = [
    'local area connection*',
    'wi-fi direct',
    'microsoft hosted network',
  ];
  
  // Protocol
  static const String protocolVersion = '1.0';
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration handshakeTimeout = Duration(seconds: 5);
  static const Duration heartbeatInterval = Duration(seconds: 30);
  
  // Retry Configuration
  static const int maxConnectionRetries = 3;
  static const Duration retryInitialDelay = Duration(seconds: 2);
}

import 'package:wifi_iot/wifi_iot.dart';
import '../../../../core/utils/logger.dart';

class WiFiConnectionService {
  /// Connects to WiFi network automatically
  static Future<bool> connectToWiFi({
    required String ssid,
    required String password,
  }) async {
    try {
      AppLogger.info('Attempting to connect to WiFi: $ssid');
      
      // Check if WiFi is enabled
      final isEnabled = await WiFiForIoTPlugin.isEnabled();
      if (!isEnabled) {
        AppLogger.info('Enabling WiFi...');
        await WiFiForIoTPlugin.setEnabled(true);
        await Future.delayed(const Duration(seconds: 2));
      }
      
      // Connect to network
      final connected = await WiFiForIoTPlugin.connect(
        ssid,
        password: password,
        security: NetworkSecurity.WPA,
        joinOnce: false, // Save network for future
      );
      
      if (!connected) {
        throw Exception('WiFi connection failed');
      }
      
      // Wait for connection to stabilize
      await Future.delayed(const Duration(seconds: 3));
      
      // Verify connection
      final currentSSID = await WiFiForIoTPlugin.getSSID();
      if (currentSSID != ssid) {
        AppLogger.warning('Connected to different network: $currentSSID');
      }
      
      AppLogger.info('✓ Successfully connected to WiFi: $ssid');
      return true;
      
    } catch (e) {
      AppLogger.error('WiFi connection failed', e);
      return false;
    }
  }
  
  /// Checks if already connected to target WiFi
  static Future<bool> isConnectedTo(String ssid) async {
    try {
      final currentSSID = await WiFiForIoTPlugin.getSSID();
      final connected = currentSSID == ssid;
      if (connected) {
        AppLogger.info('Already connected to: $ssid');
      }
      return connected;
    } catch (e) {
      AppLogger.error('Failed to check WiFi status', e);
      return false;
    }
  }
}

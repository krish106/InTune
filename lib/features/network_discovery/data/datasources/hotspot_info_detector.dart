import 'dart:io';
import '../../../../core/utils/logger.dart';

class HotspotInfoDetector {
  /// Gets Windows Mobile Hotspot SSID and password
  static Future<Map<String, String?>> getHotspotCredentials() async {
    if (!Platform.isWindows) {
      return {'ssid': null, 'password': null};
    }
    
    try {
      AppLogger.info('Retrieving Windows hotspot credentials...');
      
      // Get hotspot profile info using netsh
      final result = await Process.run('netsh', [
        'wlan',
        'show',
        'hostednetwork',
        'setting=security',
      ]);
      
      if (result.exitCode != 0) {
        AppLogger.warning('Hotspot not configured or disabled');
        return {'ssid': null, 'password': null};
      }
      
      final output = result.stdout as String;
      
      // Parse SSID
      final ssidMatch = RegExp(r'SSID name\s*:\s*"(.+)"').firstMatch(output);
      final ssid = ssidMatch?.group(1);
      
      // Parse password
      final passMatch = RegExp(r'User security key\s*:\s*(.+)').firstMatch(output);
      final password = passMatch?.group(1)?.trim();
      
      if (ssid == null || password == null || ssid.isEmpty || password.isEmpty) {
        AppLogger.warning('Could not parse hotspot credentials');
        return {'ssid': null, 'password': null};
      }
      
      AppLogger.info('✓ Retrieved hotspot credentials for: $ssid');
      return {'ssid': ssid, 'password': password};
      
    } catch (e) {
      AppLogger.error('Failed to get hotspot credentials', e);
      return {'ssid': null, 'password': null};
    }
  }
}

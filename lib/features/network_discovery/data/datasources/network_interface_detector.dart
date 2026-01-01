import 'dart:io';
import '../../../../core/constants/network_constants.dart';
import '../../../../core/exceptions/network_exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/validators.dart';

class NetworkInterfaceDetector {
  /// Detects the active network IP address (hotspot or regular WiFi)
  /// Returns the IP address if found, throws HotspotNotDetectedException if not found
  Future<String> detectHotspotIP() async {
    try {
      AppLogger.info('Starting network IP detection...');
      
      // Get all network interfaces
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        includeLinkLocal: false,
        type: InternetAddressType.IPv4,
      );
      
      AppLogger.debug('Found ${interfaces.length} network interfaces');
      
      // Strategy 1: Look for Windows Mobile Hotspot first (priority)
      final hotspotIP = _findHotspotIP(interfaces);
      if (hotspotIP != null) {
        AppLogger.info('✓ Hotspot IP detected: $hotspotIP');
        return hotspotIP;
      }
      
      // Strategy 2: Look for any WiFi adapter with valid IPv4
      final wifiIP = _findWiFiIP(interfaces);
      if (wifiIP != null) {
        AppLogger.info('✓ WiFi IP detected: $wifiIP');
        return wifiIP;
      }
      
      // Strategy 3: Use first non-loopback IPv4 (fallback)
      final firstIP = _findFirstIPv4(interfaces);
      if (firstIP != null) {
        AppLogger.info('✓ Network IP detected (fallback): $firstIP');
        return firstIP;
      }
      
      // No IP found - throw exception
      AppLogger.warning('Could not automatically detect network IP');
      throw HotspotNotDetectedException();
      
    } catch (e) {
      if (e is HotspotNotDetectedException) rethrow;
      AppLogger.error('Error detecting network IP', e);
      throw NetworkException('Failed to detect network interfaces: $e');
    }
  }
  
  /// Strategy 1: Find Windows Mobile Hotspot IP
  String? _findHotspotIP(List<NetworkInterface> interfaces) {
    for (final interface in interfaces) {
      final name = interface.name.toLowerCase();
      
      // Check if name matches hotspot adapter keywords
      final matchesName = NetworkConstants.hotspotAdapterKeywords.any(
        (keyword) => name.contains(keyword.toLowerCase()),
      );
      
      if (matchesName) {
        // Verify it has an IP in the hotspot range
        for (final addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4) {
            final ip = addr.address;
            if (Validators.isHotspotIP(ip, NetworkConstants.hotspotIPPrefixes)) {
              AppLogger.debug('Matched hotspot: ${interface.name} -> $ip');
              return ip;
            }
          }
        }
      }
    }
    return null;
  }
  
  /// Strategy 2: Find WiFi adapter IP (any network)
  String? _findWiFiIP(List<NetworkInterface> interfaces) {
    // Common WiFi adapter keywords
    final wifiKeywords = ['wi-fi', 'wifi', 'wireless', 'wlan', 'ethernet'];
    
    for (final interface in interfaces) {
      final name = interface.name.toLowerCase();
      
      // Check if name matches WiFi keywords
      final matchesWiFi = wifiKeywords.any(
        (keyword) => name.contains(keyword),
      );
      
      if (matchesWiFi) {
        for (final addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4) {
            final ip = addr.address;
            // Accept any private IP range
            if (_isPrivateIP(ip)) {
              AppLogger.debug('Matched WiFi: ${interface.name} -> $ip');
              return ip;
            }
          }
        }
      }
    }
    return null;
  }
  
  /// Strategy 3: Get first available IPv4 (fallback)
  String? _findFirstIPv4(List<NetworkInterface> interfaces) {
    for (final interface in interfaces) {
      for (final addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4) {
          final ip = addr.address;
          if (_isPrivateIP(ip)) {
            AppLogger.debug('Using first IP: ${interface.name} -> $ip');
            return ip;
          }
        }
      }
    }
    return null;
  }
  
  /// Check if IP is in private address range
  bool _isPrivateIP(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;
    
    final first = int.tryParse(parts[0]) ?? 0;
    final second = int.tryParse(parts[1]) ?? 0;
    
    // 10.0.0.0/8
    if (first == 10) return true;
    
    // 172.16.0.0/12
    if (first == 172 && second >= 16 && second <= 31) return true;
    
    // 192.168.0.0/16
    if (first == 192 && second == 168) return true;
    
    return false;
  }
  
  /// Get all available IPv4 addresses for manual selection
  Future<List<String>> getAllIPv4Addresses() async {
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      includeLinkLocal: false,
      type: InternetAddressType.IPv4,
    );
    
    final ipList = <String>[];
    for (final interface in interfaces) {
      for (final addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4) {
          ipList.add('${addr.address} (${interface.name})');
        }
      }
    }
    
    return ipList;
  }
  
  /// Validate that an IP address is accessible by binding a test socket
  Future<bool> validateIP(String ip, int port) async {
    try {
      final server = await HttpServer.bind(ip, port);
      await server.close();
      AppLogger.debug('IP $ip:$port is valid and accessible');
      return true;
    } catch (e) {
      AppLogger.warning('IP $ip:$port validation failed: $e');
      return false;
    }
  }
}

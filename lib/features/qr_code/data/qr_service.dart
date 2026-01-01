import 'dart:convert';

class QRData {
  final String ip;
  final int port;
  final String protocol;
  final String version;
  final String serverName;
  final String? wifiSSID;
  final String? wifiPassword;
  
  QRData({
    required this.ip,
    required this.port,
    required this.protocol,
    required this.version,
    required this.serverName,
    this.wifiSSID,
    this.wifiPassword,
  });
  
  /// Encode QR data to velocitylink:// URI format
  String encode() {
    var uri = 'velocitylink://$ip:$port?name=${Uri.encodeComponent(serverName)}';
    if (wifiSSID != null && wifiPassword != null) {
      uri += '&ssid=${Uri.encodeComponent(wifiSSID!)}';
      uri += '&pass=${Uri.encodeComponent(wifiPassword!)}';
    }
    return uri;
  }
  
  /// Decode velocitylink:// URI to QRData
  /// Supports both formats:
  /// - velocitylink://IP:PORT?name=... (new format)
  /// - velocitylink://connect?ip=...&port=... (legacy format)
  static QRData decode(String data) {
    final trimmedData = data.trim();
    
    if (!trimmedData.startsWith('velocitylink://')) {
      throw FormatException('Invalid QR code format. Expected velocitylink:// URI, got: ${trimmedData.substring(0, trimmedData.length > 50 ? 50 : trimmedData.length)}');
    }

    try {
      final uri = Uri.parse(trimmedData);
      
      // Check for legacy format: velocitylink://connect?ip=...&port=...
      if (uri.host == 'connect' || uri.queryParameters.containsKey('ip')) {
        final ip = uri.queryParameters['ip'];
        final portStr = uri.queryParameters['port'];
        
        if (ip == null || ip.isEmpty) {
          throw FormatException('Missing IP address in QR code');
        }
        
        final port = int.tryParse(portStr ?? '8889') ?? 8889;
        
        return QRData(
          ip: ip,
          port: port,
          protocol: 'ws',
          version: '1.0',
          serverName: uri.queryParameters['name'] ?? 'Unknown Server',
          wifiSSID: uri.queryParameters['ssid'],
          wifiPassword: uri.queryParameters['pass'],
        );
      }
      
      // New format: velocitylink://IP:PORT?name=...
      if (uri.host.isEmpty) {
        throw FormatException('Missing host/IP in QR code');
      }
      
      // If port is 0, use default
      final port = uri.port > 0 ? uri.port : 8889;
      
      return QRData(
        ip: uri.host,
        port: port,
        protocol: 'ws',
        version: '1.0',
        serverName: uri.queryParameters['name'] ?? 'Unknown Server',
        wifiSSID: uri.queryParameters['ssid'],
        wifiPassword: uri.queryParameters['pass'],
      );
    } catch (e) {
      if (e is FormatException) rethrow;
      throw FormatException('Failed to parse QR code: $e');
    }
  }
  
  /// Get WebSocket URL from QR data
  String get wsUrl => '$protocol://$ip:$port';
  
  @override
  String toString() => 'QRData(ip: $ip, port: $port, serverName: $serverName, wifi: ${wifiSSID != null ? "configured" : "none"})';
}

class QRService {
  /// Generate QR data for server connection
  static QRData generateServerQRData({
    required String ip,
    required int port,
    required String serverName,
    String? wifiSSID,
    String? wifiPassword,
    String protocol = 'ws',
    String version = '1.0',
  }) {
    return QRData(
      ip: ip,
      port: port,
      protocol: protocol,
      version: version,
      serverName: serverName,
      wifiSSID: wifiSSID,
      wifiPassword: wifiPassword,
    );
  }
  
  /// Parse scanned QR code data
  static QRData parseScannedData(String rawData) {
    try {
      return QRData.decode(rawData);
    } catch (e) {
      throw FormatException('Invalid QR code format: $e');
    }
  }
}

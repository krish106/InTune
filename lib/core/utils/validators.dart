class Validators {
  /// Validates if a string is a valid IPv4 address
  static bool isValidIPv4(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;
    
    for (final part in parts) {
      final num = int.tryParse(part);
      if (num == null || num < 0 || num > 255) return false;
    }
    
    return true;
  }
  
  /// Validates if a port number is valid (1-65535)
  static bool isValidPort(int port) {
    return port >= 1 && port <= 65535;
  }
  
  /// Checks if an IP is in the hotspot range
  static bool isHotspotIP(String ip, List<String> prefixes) {
    return prefixes.any((prefix) => ip.startsWith(prefix));
  }
}

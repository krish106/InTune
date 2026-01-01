class NetworkException implements Exception {
  final String message;
  
  NetworkException(this.message);
  
  @override
  String toString() => 'NetworkException: $message';
}

class HotspotNotDetectedException extends NetworkException {
  HotspotNotDetectedException() 
    : super('Mobile Hotspot interface not detected. Please ensure hotspot is enabled.');
}

class WebSocketConnectionException extends NetworkException {
  WebSocketConnectionException(String reason) 
    : super('WebSocket connection failed: $reason');
}

class HandshakeFailedException extends NetworkException {
  HandshakeFailedException(String reason) 
    : super('Handshake failed: $reason');
}

class ProtocolVersionMismatchException extends NetworkException {
  ProtocolVersionMismatchException(String clientVersion, String serverVersion) 
    : super('Protocol version mismatch. Client: $clientVersion, Server: $serverVersion');
}

class ConnectionTimeoutException extends NetworkException {
  ConnectionTimeoutException() 
    : super('Connection timeout');
}

import 'device_info.dart';
import '../utils/speed_calculator.dart';

enum ConnectionStatus {
  disconnected,
  scanning,       // Android: Scanning QR
  connecting,     // Attempting WebSocket connection
  handshaking,    // Performing handshake
  connected,      // Handshake complete, ready
  error,          // Connection failed
}

class ConnectionState {
  final ConnectionStatus status;
  final DeviceInfo? remoteDevice;
  final String? sessionId;
  final String? errorMessage;
  final DateTime? connectedAt;
  
  // Phase 9: Upload Progress
  final String? currentUploadFile;
  final TransferMetrics? uploadMetrics;
  
  // Network Info
  final String? connectedAddress; // IP address of remote device
  
  ConnectionState({
    required this.status,
    this.remoteDevice,
    this.sessionId,
    this.errorMessage,
    this.connectedAt,
    this.currentUploadFile,
    this.uploadMetrics,
    this.connectedAddress,
  });
  
  ConnectionState copyWith({
    ConnectionStatus? status,
    DeviceInfo? remoteDevice,
    String? sessionId,
    String? errorMessage,
    DateTime? connectedAt,
    String? currentUploadFile,
    TransferMetrics? uploadMetrics,
    String? connectedAddress,
  }) {
    return ConnectionState(
      status: status ?? this.status,
      remoteDevice: remoteDevice ?? this.remoteDevice,
      sessionId: sessionId ?? this.sessionId,
      errorMessage: errorMessage ?? this.errorMessage,
      connectedAt: connectedAt ?? this.connectedAt,
      currentUploadFile: currentUploadFile ?? this.currentUploadFile,
      uploadMetrics: uploadMetrics ?? this.uploadMetrics,
      connectedAddress: connectedAddress ?? this.connectedAddress,
    );
  }
  
  bool get isConnected => status == ConnectionStatus.connected;
  bool get isDisconnected => status == ConnectionStatus.disconnected;
  bool get hasError => status == ConnectionStatus.error;
  
  @override
  String toString() {
    return 'ConnectionState(status: $status, sessionId: $sessionId)';
  }
}

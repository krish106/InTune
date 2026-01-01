import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/connection_state.dart';
import '../../../../core/models/device_info.dart';
import '../../../../core/models/message_envelope.dart';
import '../../../../core/constants/network_constants.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/exceptions/network_exceptions.dart';
import '../../../network_discovery/data/datasources/network_interface_detector.dart';
import '../../../../core/utils/byte_counting_transformer.dart';
import '../../../remote_file_system/data/remote_file_server.dart';
import '../../data/datasources/websocket_server.dart';
import '../../data/datasources/websocket_client.dart';
import 'package:uuid/uuid.dart';
import '../../../file_transfer/data/transfer_history_service.dart';

/// Provider for current connection state
final connectionProvider = StateNotifierProvider<ConnectionNotifier, ConnectionState>((ref) {
  return ConnectionNotifier();
});

class ConnectionNotifier extends StateNotifier<ConnectionState> {
  WebSocketServer? _server;
  WebSocketClient? _client;
  final _fileServer = RemoteFileServer();
  final _networkDetector = NetworkInterfaceDetector();
  
  ConnectionNotifier() : super(ConnectionState(status: ConnectionStatus.disconnected));
  
  final List<Future<void> Function(MessageEnvelope)> _messageHandlers = [];
  
  void registerMessageHandler(Future<void> Function(MessageEnvelope) handler) {
    _messageHandlers.add(handler);
    AppLogger.info('✅ Message handler registered (total: ${_messageHandlers.length})');
  }
  
  /// Start server (Windows Host)
  Future<String?> startServer(DeviceInfo hostInfo) async {
    try {
      state = state.copyWith(status: ConnectionStatus.connecting);
      AppLogger.info('Starting VelocityLink server...');
      
      // Detect hotspot IP
      String? ip;
      try {
        ip = await _networkDetector.detectHotspotIP();
      } catch (e) {
        if (e is HotspotNotDetectedException) {
          // Return null to trigger manual IP selection UI
          state = state.copyWith(
            status: ConnectionStatus.error,
            errorMessage: 'Hotspot IP not detected. Please select manually.',
          );
          return null;
        }
        rethrow;
      }
      
      // Validate IP
      final isValid = await _networkDetector.validateIP(ip, NetworkConstants.defaultPort);
      if (!isValid) {
        state = state.copyWith(
          status: ConnectionStatus.error,
          errorMessage: 'Cannot bind to $ip:${NetworkConstants.defaultPort}',
        );
        return null;
      }
      
      // Start WebSocket server
      _server = WebSocketServer(hostInfo: hostInfo);
      
      _server!.onClientConnected = (clientInfo, sessionId, ip) {
        AppLogger.info('Client connected: ${clientInfo.deviceName} ($ip)');
        state = state.copyWith(
          status: ConnectionStatus.connected,
          remoteDevice: clientInfo,
          sessionId: sessionId,
          connectedAt: DateTime.now(),
          connectedAddress: ip,
        );
      };
      
      _server!.onClientDisconnected = () {
        AppLogger.info('Client disconnected');
        state = state.copyWith(
          status: ConnectionStatus.disconnected,
          remoteDevice: null,
          sessionId: null,
        );
      };
      
      _server!.onMessageReceived = (message) {
        _handleIncomingMessage(message);
      };
      
      // Phase 9: File Upload Callbacks
      _server!.onUploadProgress = (filename, metrics) {
        state = state.copyWith(
          currentUploadFile: filename,
          uploadMetrics: metrics,
        );
      };
      
      _server!.onUploadComplete = (filename, filePath) async {
        state = state.copyWith(
          currentUploadFile: null,
          uploadMetrics: null,
        );
        // Log to history here or notify UI
        // await TransferHistoryService.addLog(...); // Can be added later
      };
      
      await _server!.start(ip, NetworkConstants.defaultPort);
      
      state = state.copyWith(status: ConnectionStatus.connected);
      return ip;
      
    } catch (e) {
      AppLogger.error('Failed to start server', e);
      state = state.copyWith(
        status: ConnectionStatus.error,
        errorMessage: e.toString(),
      );
      return null;
    }
  }
  
  /// Connect to server (Android Client)
  Future<void> connectToServer(String ip, int port, DeviceInfo clientInfo) async {
    try {
      state = state.copyWith(status: ConnectionStatus.connecting);
      AppLogger.info('Connecting to server at $ip:$port');
      
      // Create WebSocket client
      _client = WebSocketClient(clientInfo: clientInfo);
      
      _client!.onConnected = (hostInfo, sessionId) {
        AppLogger.info('Connected to host: ${hostInfo.deviceName}');
        state = state.copyWith(
          status: ConnectionStatus.connected,
          remoteDevice: hostInfo,
          sessionId: sessionId,
          connectedAt: DateTime.now(),
        );
      };
      
      _client!.onDisconnected = () {
        AppLogger.info('Disconnected from server');
        state = state.copyWith(
          status: ConnectionStatus.disconnected,
          remoteDevice: null,
          sessionId: null,
        );
      };
      
      _client!.onMessageReceived = (message) {
        _handleIncomingMessage(message);
      };
      
      // Connect to server
      await _client!.connect(ip, port);
      
      state = state.copyWith(connectedAddress: ip);
      
      // Phase 10: Start Remote File Server (Android)
      await _fileServer.start();
      
      // Perform handshake
      state = state.copyWith(status: ConnectionStatus.handshaking);
      await _client!.performHandshake();
      
    } catch (e) {
      AppLogger.error('Failed to connect to server', e);
      state = state.copyWith(
        status: ConnectionStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }
  
  /// Disconnect from current connection
  Future<void> disconnect() async {
    AppLogger.info('Disconnecting...');
    
    await _server?.stop();
    await _client?.disconnect();
    await _fileServer.stop();
    
    _server = null;
    _client = null;
    
    state = ConnectionState(status: ConnectionStatus.disconnected);
  }
  
  Future<void> _handleIncomingMessage(MessageEnvelope message) async {
    if (message.type == MessageType.inputEvent) {
       print('📨 Windows received InputEvent.');
    }
    
    if (_messageHandlers.isNotEmpty) {
      print('🔵 Calling ${_messageHandlers.length} message handlers for ${message.type}');
      for (final handler in _messageHandlers) {
        try {
          await handler(message);
        } catch (e, stack) {
          print('🔴 ERROR in message handler: $e');
          print('Stack: $stack');
        }
      }
      print('🟢 All handlers completed for ${message.type}');
    } else {
      print('❌ No message handlers registered for ${message.type}');
    }
    
    switch (message.type) {
      case MessageType.handshakeRequest:
        // Already handled by server/client
        break;
        
      case MessageType.handshakeResponse:
        // _handleHandshakeResponse(message); // This method is not defined in the provided context
        break;
        
      case MessageType.handshakeAck:
        // _handleHandshakeAck(message); // This method is not defined in the provided context
        break;
        
      case MessageType.clipboard:
        // Forward to clipboard provider
        _handleClipboardMessage(message);
        break;
        
      case MessageType.heartbeat:
        // Handle heartbeat
        break;
        
      case MessageType.inputEvent:
      case MessageType.mediaControl:
      case MessageType.fileTransfer:
      case MessageType.deviceStats:    // Phase 8: Handled by registered handler
      case MessageType.remoteCommand:  // Phase 8: Handled by registered handler
        // Handled by registered message handler
        break;
        
      default:
        AppLogger.warning('Unhandled message type: ${message.type}');
    }
  }
  
  void _handleClipboardMessage(MessageEnvelope message) {
    try {
      // Import will be added at top of file
      // ref.read(clipboardProvider.notifier).handleRemoteClipboard(message.payload);
      AppLogger.info('Clipboard message received, forwarding to clipboard provider');
    } catch (e) {
      AppLogger.error('Failed to handle clipboard message', e);
    }
  }
  
  /// Send a message
  void sendMessage(MessageEnvelope message) {
    if (_server != null) {
      _server!.sendMessage(message);
    } else if (_client != null) {
      _client!.sendMessage(message);
    } else {
      AppLogger.warning('Cannot send message: Not connected');
    }
  }
  
  /// Get available IP addresses for manual selection
  Future<List<String>> getAvailableIPs() async {
    return await _networkDetector.getAllIPv4Addresses();
  }
  
  bool get isServer => _server != null;
  bool get isClient => _client != null;
}

/// Provider for device information
/// Provider for device information
final deviceInfoProvider = StateProvider<DeviceInfo>((ref) {
  // Get persisted or default values
  final box = TransferHistoryService.settingsBox;
  final savedId = box?.get('device_id') as String?;
  final savedName = box?.get('device_name') as String?;
  
  final deviceId = savedId ?? const Uuid().v4();
  if (savedId == null) {
     box?.put('device_id', deviceId);
  }
  
  final defaultName = Platform.isWindows ? Platform.localHostname : 'Velocity Client';
  final deviceName = savedName ?? defaultName;

  final role = Platform.isWindows ? DeviceRole.host : DeviceRole.client;
  final platform = Platform.isWindows ? PlatformType.windows : PlatformType.android;
  
  return DeviceInfo(
    deviceId: deviceId,
    deviceName: deviceName,
    role: role,
    platform: platform,
    appVersion: AppConstants.appVersion,
    osVersion: Platform.operatingSystemVersion,
  );
});

import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/network_constants.dart';
import '../../../../core/models/message_envelope.dart';
import '../../../../core/models/handshake_packet.dart';
import '../../../../core/models/device_info.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/exceptions/network_exceptions.dart';

class WebSocketClient {
  WebSocketChannel? _channel;
  final DeviceInfo clientInfo;
  String? _sessionId;
  
  // Callbacks
  Function(DeviceInfo hostInfo, String sessionId)? onConnected;
  Function()? onDisconnected;
  Function(MessageEnvelope message)? onMessageReceived;
  
  WebSocketClient({required this.clientInfo});
  
  /// Connect to the WebSocket server
  Future<void> connect(String ip, int port) async {
    try {
      final wsUrl = 'ws://$ip:$port${NetworkConstants.wsPath}';
      AppLogger.info('Connecting to WebSocket server: $wsUrl');
      
      _channel = WebSocketChannel.connect(
        Uri.parse(wsUrl),
        protocols: ['websocket'],
      );
      
      // Wait for connection to establish
      await _channel!.ready;
      
      AppLogger.info('✓ WebSocket connection established');
      
      // Listen to incoming messages
      _channel!.stream.listen(
        (message) => _handleIncomingMessage(message as String),
        onDone: () {
          AppLogger.info('Disconnected from server');
          _channel = null;
          onDisconnected?.call();
        },
        onError: (error) {
          AppLogger.error('WebSocket error', error);
          _channel = null;
          onDisconnected?.call();
        },
      );
      
    } catch (e) {
      AppLogger.error('Failed to connect to WebSocket server', e);
      throw WebSocketConnectionException('Connection failed: $e');
    }
  }
  
  /// Disconnect from the server
  Future<void> disconnect() async {
    await _channel?.sink.close();
    _channel = null;
    _sessionId = null;
    AppLogger.info('Disconnected from server');
  }
  
  /// Perform handshake with the server
  Future<void> performHandshake() async {
    if (_channel == null) {
      throw WebSocketConnectionException('Not connected to server');
    }
    
    try {
      AppLogger.info('Initiating handshake...');
      
      final request = HandshakeRequest(
        clientInfo: clientInfo,
        protocolVersion: NetworkConstants.protocolVersion,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
      
      final envelope = MessageEnvelope(
        type: MessageType.handshakeRequest,
        messageId: const Uuid().v4(),
        timestamp: DateTime.now(),
        payload: request.toPayload(),
      );
      
      sendMessage(envelope);
      AppLogger.debug('Handshake request sent');
      
    } catch (e) {
      AppLogger.error('Handshake failed', e);
      throw HandshakeFailedException('Failed to send handshake: $e');
    }
  }
  
  /// Send a message to the server
  void sendMessage(MessageEnvelope message) {
    if (_channel == null) {
      AppLogger.warning('Cannot send message: Not connected');
      return;
    }
    
    try {
      final json = jsonEncode(message.toJson());
      _channel!.sink.add(json);
      AppLogger.debug('Sent message: ${message.type}');
    } catch (e) {
      AppLogger.error('Failed to send message', e);
    }
  }
  
  /// Handle incoming WebSocket messages
  void _handleIncomingMessage(String rawMessage) {
    try {
      final json = jsonDecode(rawMessage) as Map<String, dynamic>;
      final envelope = MessageEnvelope.fromJson(json);
      
      AppLogger.debug('Received message: ${envelope.type}');
      
      // Handle handshake response specifically
      if (envelope.type == MessageType.handshakeResponse) {
        _handleHandshakeResponse(envelope);
      } else {
        onMessageReceived?.call(envelope);
      }
    } catch (e) {
      AppLogger.error('Failed to process incoming message', e);
    }
  }
  
  /// Handle handshake response from server
  void _handleHandshakeResponse(MessageEnvelope envelope) {
    try {
      final response = HandshakeResponse.fromPayload(envelope.payload);
      
      if (!response.accepted) {
        AppLogger.error('Handshake rejected: ${response.rejectionReason}');
        throw HandshakeFailedException(response.rejectionReason ?? 'Unknown reason');
      }
      
      AppLogger.info('✓ Handshake accepted by ${response.hostInfo.deviceName}');
      _sessionId = response.sessionId;
      
      // Send ACK
      _sendHandshakeAck(response.sessionId);
      
      // Notify connection established
      onConnected?.call(response.hostInfo, _sessionId!);
      
    } catch (e) {
      AppLogger.error('Failed to handle handshake response', e);
    }
  }
  
  /// Send handshake acknowledgment to server
  void _sendHandshakeAck(String sessionId) {
    final ack = HandshakeAck(
      sessionId: sessionId,
      ready: true,
    );
    
    final envelope = MessageEnvelope(
      type: MessageType.handshakeAck,
      messageId: const Uuid().v4(),
      timestamp: DateTime.now(),
      payload: ack.toPayload(),
    );
    
    sendMessage(envelope);
    AppLogger.debug('Handshake ACK sent');
  }
  
  bool get isConnected => _channel != null;
  String? get sessionId => _sessionId;
}

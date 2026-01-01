import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/network_constants.dart';
import '../../../../core/models/message_envelope.dart';
import '../../../../core/models/handshake_packet.dart';
import '../../../../core/models/device_info.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/exceptions/network_exceptions.dart';
import '../../../../core/utils/speed_calculator.dart';
import '../../../../core/utils/byte_counting_transformer.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class WebSocketServer {
  HttpServer? _server;
  WebSocketChannel? _clientChannel;
  final DeviceInfo hostInfo;
  String? _sessionId;
  
  // Callbacks
  // Callbacks
  Function(DeviceInfo clientInfo, String sessionId, String? clientIp)? onClientConnected;
  Function()? onClientDisconnected;
  Function(MessageEnvelope message)? onMessageReceived;
  
  WebSocketServer({required this.hostInfo});
  
  /// Start the WebSocket server on the given IP and port
  Future<void> start(String ip, int port) async {
    try {
      AppLogger.info('Starting WebSocket server on $ip:$port');
      
      final handler = Cascade()
          .add(_createWebSocketHandler())
          .add(_createHttpHandler())
          .handler;
      
      _server = await shelf_io.serve(
        handler,
        ip,
        port,
      );
      
      AppLogger.info('✓ WebSocket server started successfully on ws://$ip:$port${NetworkConstants.wsPath}');
    } catch (e) {
      AppLogger.error('Failed to start WebSocket server', e);
      throw WebSocketConnectionException('Failed to start server: $e');
    }
  }
  
  /// Stop the WebSocket server
  Future<void> stop() async {
    await _clientChannel?.sink.close();
    await _server?.close(force: true);
    _server = null;
    _clientChannel = null;
    AppLogger.info('WebSocket server stopped');
  }
  
  /// Send a message to the connected client
  void sendMessage(MessageEnvelope message) {
    if (_clientChannel == null) {
      AppLogger.warning('Cannot send message: No client connected');
      return;
    }
    
    try {
      final json = jsonEncode(message.toJson());
      _clientChannel!.sink.add(json);
      AppLogger.debug('Sent message: ${message.type}');
    } catch (e) {
      AppLogger.error('Failed to send message', e);
    }
  }
  
  /// Create WebSocket upgrade handler
  Handler _createWebSocketHandler() {
    final wsHandler = webSocketHandler((WebSocketChannel channel) {
      AppLogger.info('WebSocket client connected');
      _clientChannel = channel;
      
      // Listen to incoming messages
      channel.stream.listen(
        (message) => _handleIncomingMessage(message as String),
        onDone: () {
          AppLogger.info('Client disconnected');
          _clientChannel = null;
          onClientDisconnected?.call();
        },
        onError: (error) {
          AppLogger.error('WebSocket error', error);
          _clientChannel = null;
        },
      );
    });

    // Wrap to capture IP
    return (Request request) {
       if (request.context['shelf.io.connection_info'] != null) {
          final info = request.context['shelf.io.connection_info'] as HttpConnectionInfo;
          _clientIP = info.remoteAddress.address;
       }
       return wsHandler(request);
    };
  }
  
  String? _clientIP;
  
  /// Handle incoming WebSocket messages
  void _handleIncomingMessage(String rawMessage) {
    try {
      final json = jsonDecode(rawMessage) as Map<String, dynamic>;
      final envelope = MessageEnvelope.fromJson(json);
      
      AppLogger.debug('Received message: ${envelope.type}');
      
      // Handle handshake request specifically
      if (envelope.type == MessageType.handshakeRequest) {
        _handleHandshakeRequest(envelope);
      } else {
        onMessageReceived?.call(envelope);
      }
    } catch (e) {
      AppLogger.error('Failed to process incoming message', e);
    }
  }
  
  /// Handle handshake request from client
  void _handleHandshakeRequest(MessageEnvelope envelope) {
    try {
      final request = HandshakeRequest.fromPayload(envelope.payload);
      
      AppLogger.info('Handshake request from: ${request.clientInfo.deviceName}');
      
      // Validate protocol version
      if (request.protocolVersion != NetworkConstants.protocolVersion) {
        final response = HandshakeResponse(
          hostInfo: hostInfo,
          accepted: false,
          rejectionReason: 'Protocol version mismatch',
          serverTimestamp: DateTime.now().millisecondsSinceEpoch,
          sessionId: '',
        );
        
        _sendHandshakeResponse(response);
        return;
      }
      
      // Accept the handshake
      _sessionId = const Uuid().v4();
      final response = HandshakeResponse(
        hostInfo: hostInfo,
        accepted: true,
        serverTimestamp: DateTime.now().millisecondsSinceEpoch,
        sessionId: _sessionId!,
      );
      
      _sendHandshakeResponse(response);
      
      // Wait for ACK, then notify connection established
      // This will be handled by the next message received
      onClientConnected?.call(request.clientInfo, _sessionId!, _clientIP);
      
    } catch (e) {
      AppLogger.error('Failed to handle handshake request', e);
    }
  }
  
  /// Send handshake response to client
  void _sendHandshakeResponse(HandshakeResponse response) {
    final envelope = MessageEnvelope(
      type: MessageType.handshakeResponse,
      messageId: const Uuid().v4(),
      timestamp: DateTime.now(),
      payload: response.toPayload(),
    );
    
    sendMessage(envelope);
  }
  
  /// Create HTTP handler for file transfer
  Handler _createHttpHandler() {
    return (Request request) async {
      if (request.url.path == 'upload' && request.method == 'POST') {
        AppLogger.info('📥 Receiving file upload request...');
        
        try {
          // Extract headers
          final filename = request.headers['x-filename'] ?? 'unknown_file';
          final fileSize = int.tryParse(request.headers['content-length'] ?? '0') ?? 0;
          
          if (filename.isEmpty || fileSize == 0) {
            return Response.badRequest(body: 'Missing filename or content-length');
          }
          
          // Determine save path
          final downloadPath = await _getDownloadPath();
          final savePath = p.join(downloadPath, filename);
          final file = File(savePath);
          final sink = file.openWrite();
          
          // Setup progress tracking
          final speedCalculator = SpeedCalculator();
          
          // Use ByteCountingTransformer to monitor stream
          final monitoredStream = request.read().transform(
            ByteCountingTransformer(
              onProgress: (bytesRead) {
                final metrics = speedCalculator.addSample(bytesRead, fileSize);
                
                // Update UI via callback
                onUploadProgress?.call(filename, metrics);
              },
            ),
          );
          
          // Pipe to file
          await monitoredStream.pipe(sink);
          
          AppLogger.info('✅ File received: $filename ($fileSize bytes)');
          
          // Notify completion
          onUploadComplete?.call(filename, savePath);
          
          return Response.ok('File uploaded successfully');
          
        } catch (e) {
          AppLogger.error('File upload failed', e);
          return Response.internalServerError(body: 'Upload failed: $e');
        }
      }
      
      if (request.url.path == NetworkConstants.wsPath.substring(1)) {
        // This is handled by WebSocket handler
        return Response.notFound('Use WebSocket connection');
      }
      
      return Response.ok('VelocityLink Server Running');
    };
  }
  
  Future<String> _getDownloadPath() async {
    // Basic impl, ideally reuse TransferHistoryService logic or pass it in
    if (Platform.isWindows) {
      return (await getDownloadsDirectory())!.path;
    }
    return (await getApplicationDocumentsDirectory()).path;
  }
  
  // New Callbacks for File Upload
  Function(String filename, TransferMetrics metrics)? onUploadProgress;
  Function(String filename, String filePath)? onUploadComplete;
  
  bool get isRunning => _server != null;
  bool get hasClient => _clientChannel != null;
  String? get sessionId => _sessionId;
}

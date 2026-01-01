enum MessageType {
  // Phase 1: Connection
  handshakeRequest,
  handshakeResponse,
  handshakeAck,
  capabilities,
  heartbeat,
  
  // Phase 2: Data Transfer
  clipboard,
  fileTransfer, // Generic header/chunk/end
  fileTransferRequest,
  fileTransferAccept,
  fileTransferReject,
  fileTransferProgress,
  fileTransferComplete,
  fileTransferError,
  
  // Phase 3 & 4 (Future)
  screenFrame,
  inputEvent,
  pairingRequest,
  pairingResponse,
  inputControl,
  error,
  
  // Phase 5: Continuity
  notification,
  mediaControl,
  unlock,
  browserHandoff,
  
  // Phase 8: Functionality Patch
  deviceStats,     // Android -> Windows: battery, signal, storage
  remoteCommand,   // Windows -> Android: RING, UNLOCK, etc.
}

class MessageEnvelope {
  final MessageType type;
  final String messageId;
  final DateTime timestamp;
  final Map<String, dynamic> payload;
  
  MessageEnvelope({
    required this.type,
    required this.messageId,
    required this.timestamp,
    required this.payload,
  });
  
  factory MessageEnvelope.fromJson(Map<String, dynamic> json) {
    return MessageEnvelope(
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      messageId: json['messageId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      payload: json['payload'] as Map<String, dynamic>,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'messageId': messageId,
    'timestamp': timestamp.toIso8601String(),
    'payload': payload,
  };
  
  @override
  String toString() {
    return 'MessageEnvelope(type: $type, messageId: $messageId)';
  }
}

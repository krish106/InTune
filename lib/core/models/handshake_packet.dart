import 'device_info.dart';

class HandshakeRequest {
  final DeviceInfo clientInfo;
  final String protocolVersion;
  final int timestamp;
  
  HandshakeRequest({
    required this.clientInfo,
    required this.protocolVersion,
    required this.timestamp,
  });
  
  Map<String, dynamic> toPayload() => {
    'clientInfo': clientInfo.toJson(),
    'protocolVersion': protocolVersion,
    'timestamp': timestamp,
  };
  
  static HandshakeRequest fromPayload(Map<String, dynamic> payload) {
    return HandshakeRequest(
      clientInfo: DeviceInfo.fromJson(payload['clientInfo'] as Map<String, dynamic>),
      protocolVersion: payload['protocolVersion'] as String,
      timestamp: payload['timestamp'] as int,
    );
  }
}

class HandshakeResponse {
  final DeviceInfo hostInfo;
  final bool accepted;
  final String? rejectionReason;
  final int serverTimestamp;
  final String sessionId;
  
  HandshakeResponse({
    required this.hostInfo,
    required this.accepted,
    this.rejectionReason,
    required this.serverTimestamp,
    required this.sessionId,
  });
  
  Map<String, dynamic> toPayload() => {
    'hostInfo': hostInfo.toJson(),
    'accepted': accepted,
    'rejectionReason': rejectionReason,
    'serverTimestamp': serverTimestamp,
    'sessionId': sessionId,
  };
  
  static HandshakeResponse fromPayload(Map<String, dynamic> payload) {
    return HandshakeResponse(
      hostInfo: DeviceInfo.fromJson(payload['hostInfo'] as Map<String, dynamic>),
      accepted: payload['accepted'] as bool,
      rejectionReason: payload['rejectionReason'] as String?,
      serverTimestamp: payload['serverTimestamp'] as int,
      sessionId: payload['sessionId'] as String,
    );
  }
}

class HandshakeAck {
  final String sessionId;
  final bool ready;
  
  HandshakeAck({
    required this.sessionId,
    required this.ready,
  });
  
  Map<String, dynamic> toPayload() => {
    'sessionId': sessionId,
    'ready': ready,
  };
  
  static HandshakeAck fromPayload(Map<String, dynamic> payload) {
    return HandshakeAck(
      sessionId: payload['sessionId'] as String,
      ready: payload['ready'] as bool,
    );
  }
}

class DeviceCapabilities {
  final bool supportsFileTransfer;
  final bool supportsClipboard;
  final bool supportsScreenShare;
  final int maxFileSize;
  final List<String> supportedFormats;
  
  DeviceCapabilities({
    required this.supportsFileTransfer,
    required this.supportsClipboard,
    required this.supportsScreenShare,
    required this.maxFileSize,
    required this.supportedFormats,
  });
  
  Map<String, dynamic> toPayload() => {
    'supportsFileTransfer': supportsFileTransfer,
    'supportsClipboard': supportsClipboard,
    'supportsScreenShare': supportsScreenShare,
    'maxFileSize': maxFileSize,
    'supportedFormats': supportedFormats,
  };
  
  static DeviceCapabilities fromPayload(Map<String, dynamic> payload) {
    return DeviceCapabilities(
      supportsFileTransfer: payload['supportsFileTransfer'] as bool,
      supportsClipboard: payload['supportsClipboard'] as bool,
      supportsScreenShare: payload['supportsScreenShare'] as bool,
      maxFileSize: payload['maxFileSize'] as int,
      supportedFormats: List<String>.from(payload['supportedFormats']),
    );
  }
}

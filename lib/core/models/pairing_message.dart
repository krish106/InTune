class PairingRequest {
  final String deviceId;
  final String deviceName;
  final String? existingToken;
  
  PairingRequest({
    required this.deviceId,
    required this.deviceName,
    this.existingToken,
  });
  
  Map<String, dynamic> toPayload() => {
    'deviceId': deviceId,
    'deviceName': deviceName,
    'existingToken': existingToken,
  };
  
  static PairingRequest fromPayload(Map<String, dynamic> payload) {
    return PairingRequest(
      deviceId: payload['deviceId'] as String,
      deviceName: payload['deviceName'] as String,
      existingToken: payload['existingToken'] as String?,
    );
  }
}

class PairingResponse {
  final bool requiresPin;
  final String? pin;
  final String? token;
  final bool accepted;
  final String? reason;
  
  PairingResponse({
    required this.requiresPin,
    this.pin,
    this.token,
    required this.accepted,
    this.reason,
  });
  
  Map<String, dynamic> toPayload() => {
    'requiresPin': requiresPin,
    'pin': pin,
    'token': token,
    'accepted': accepted,
    'reason': reason,
  };
  
  static PairingResponse fromPayload(Map<String, dynamic> payload) {
    return PairingResponse(
      requiresPin: payload['requiresPin'] as bool,
      pin: payload['pin'] as String?,
      token: payload['token'] as String?,
      accepted: payload['accepted'] as bool,
      reason: payload['reason'] as String?,
    );
  }
}

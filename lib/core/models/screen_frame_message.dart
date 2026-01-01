import 'dart:typed_data';

class ScreenFrameMessage {
  final int frameNumber;
  final int width;
  final int height;
  final int quality;
  final Uint8List? jpegData; // Binary data, sent separately
  
  ScreenFrameMessage({
    required this.frameNumber,
    required this.width,
    required this.height,
    required this.quality,
    this.jpegData,
  });
  
  Map<String, dynamic> toPayload() => {
    'frameNumber': frameNumber,
    'width': width,
    'height': height,
    'quality': quality,
    'dataSize': jpegData?.length ?? 0,
  };
  
  static ScreenFrameMessage fromPayload(Map<String, dynamic> payload) {
    return ScreenFrameMessage(
      frameNumber: payload['frameNumber'] as int,
      width: payload['width'] as int,
      height: payload['height'] as int,
      quality: payload['quality'] as int,
    );
  }
  
  @override
  String toString() {
    return 'ScreenFrameMessage(frame: $frameNumber, ${width}x$height, quality: $quality)';
  }
}

class ScreenControlMessage {
  final String action; // 'start', 'stop', 'quality'
  final Map<String, dynamic> parameters;
  
  ScreenControlMessage({
    required this.action,
    required this.parameters,
  });
  
  Map<String, dynamic> toPayload() => {
    'action': action,
    'parameters': parameters,
  };
  
  static ScreenControlMessage fromPayload(Map<String, dynamic> payload) {
    return ScreenControlMessage(
      action: payload['action'] as String,
      parameters: payload['parameters'] as Map<String, dynamic>,
    );
  }
}

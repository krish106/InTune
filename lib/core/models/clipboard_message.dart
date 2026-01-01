enum ClipboardContentType { text, url }

class ClipboardMessage {
  final String content;
  final ClipboardContentType type;
  final DateTime timestamp;
  final String sourceDeviceId;
  final String sourceDeviceName;
  
  ClipboardMessage({
    required this.content,
    required this.type,
    required this.timestamp,
    required this.sourceDeviceId,
    required this.sourceDeviceName,
  });
  
  /// Detect if content is a URL
  static ClipboardContentType detectType(String content) {
    final urlPattern = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
      caseSensitive: false,
    );
    
    return urlPattern.hasMatch(content) 
        ? ClipboardContentType.url 
        : ClipboardContentType.text;
  }
  
  Map<String, dynamic> toPayload() => {
    'content': content,
    'type': type.name,
    'timestamp': timestamp.toIso8601String(),
    'sourceDeviceId': sourceDeviceId,
    'sourceDeviceName': sourceDeviceName,
  };
  
  static ClipboardMessage fromPayload(Map<String, dynamic> payload) {
    return ClipboardMessage(
      content: payload['content'] as String,
      type: ClipboardContentType.values.firstWhere(
        (e) => e.name == payload['type'],
      ),
      timestamp: DateTime.parse(payload['timestamp'] as String),
      sourceDeviceId: payload['sourceDeviceId'] as String,
      sourceDeviceName: payload['sourceDeviceName'] as String,
    );
  }
  
  @override
  String toString() {
    return 'ClipboardMessage(type: $type, from: $sourceDeviceName, length: ${content.length})';
  }
}

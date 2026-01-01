class NotificationMessage {
  final String appName;
  final String title;
  final String body;
  final DateTime timestamp;
  final String? icon;
  
  NotificationMessage({
    required this.appName,
    required this.title,
    required this.body,
    required this.timestamp,
    this.icon,
  });
  
  Map<String, dynamic> toPayload() => {
    'appName': appName,
    'title': title,
    'body': body,
    'timestamp': timestamp.toIso8601String(),
    if (icon != null) 'icon': icon,
  };
  
  factory NotificationMessage.fromPayload(Map<String, dynamic> payload) {
    return NotificationMessage(
      appName: payload['appName'] as String,
      title: payload['title'] as String,
      body: payload['body'] as String,
      timestamp: DateTime.parse(payload['timestamp'] as String),
      icon: payload['icon'] as String?,
    );
  }
}

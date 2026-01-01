import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../core/models/message_envelope.dart';
import '../../../core/models/notification_message.dart';
import '../../../core/utils/logger.dart';

class NotificationDisplayService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    const initializationSettings = InitializationSettings(
      windows: WindowsInitializationSettings(
        appName: 'VelocityLink',
        appUserModelId: 'com.velocitylink.app',
      ),
    );

    await _notifications.initialize(initializationSettings);
    _initialized = true;
    AppLogger.info('✅ Notification service initialized');
  }

  static Future<void> showNotification(NotificationMessage notification) async {
    if (!_initialized) await initialize();

    try {
      await _notifications.show(
        notification.hashCode,
        '📱 ${notification.appName}',
        notification.body,
        const NotificationDetails(
          windows: WindowsNotificationDetails(
            subtitle: null,
          ),
        ),
      );

      AppLogger.info('🔔 Shown notification: ${notification.title}');
    } catch (e) {
      AppLogger.error('Failed to show notification', e);
    }
  }

  static Future<void> handleNotificationMessage(Map<String, dynamic> payload) async {
    final notification = NotificationMessage.fromPayload(payload);
    await showNotification(notification);
  }
}

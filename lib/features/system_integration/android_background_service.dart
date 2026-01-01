import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AndroidBackgroundService {
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    // Notification channel for foreground service
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'my_foreground', // id
      'MY FOREGROUND SERVICE', // title
      description: 'This channel is used for important notifications.',
      importance: Importance.low,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'my_foreground',
        initialNotificationTitle: 'InTune Service',
        initialNotificationContent: 'Running in background',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    // Only available for flutter 3.0.0 and later
    DartPluginRegistrant.ensureInitialized();

    // This runs in a separate isolate (or main isolate if configured differently?)
    // Actually, 'flutter_background_service' documentation says onStart runs in a separate isolate.
    // BUT we want to keep OUR app alive.
    // If we want the UI connection to stay alive when app is minimized, enabling Foreground Mode 
    // usually keeps the Main Isolate alive on Android if attached?
    // Wait, detached mode spawns separate isolate.
    
    // Simplest approach: The SERVICE keeps the process alive.
    // The UI Isolate (Riverpod connection) might still be paused if we don't hold a WakeLock?
    // 'flutter_background_service' auto holds WakeLock if configured?
    
    // We just need to handle simple "I am alive" here.
    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    // Bring to foreground logic if needed
    Timer.periodic(const Duration(seconds: 15), (timer) async {
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          // Update notification logic if needed
        }
      }
      
      // Perform simple upkeep
      // service.invoke('update');
    });
  }

  @pragma('vm:entry-point')
  static bool onIosBackground(ServiceInstance service) {
    return true;
  }
}

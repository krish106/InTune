import 'dart:async';
import 'dart:io';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../core/models/message_envelope.dart';
import 'package:uuid/uuid.dart';

/// Service for monitoring device stats and sending to Windows host
class DeviceMonitorService {
  Timer? _timer;
  Function(MessageEnvelope)? _sendMessage;
  final Battery _battery = Battery();

  /// Start periodic monitoring and reporting
  void startMonitoring(Function(MessageEnvelope) sendMessage) {
    _sendMessage = sendMessage;
    
    // Only monitor on Android
    if (!Platform.isAndroid) {
      print('📊 DeviceMonitorService: Skipping on non-Android platform');
      return;
    }
    
    // Send initial stats
    _gatherAndSendStats();
    
    // Then every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      _gatherAndSendStats();
    });
    
    print('📊 DeviceMonitorService started');
  }

  Future<void> _gatherAndSendStats() async {
    if (_sendMessage == null) return;
    
    try {
      // Get battery level
      int batteryLevel = 100;
      bool isCharging = false;
      try {
        batteryLevel = await _battery.batteryLevel;
        final batteryState = await _battery.batteryState;
        isCharging = batteryState == BatteryState.charging || 
                     batteryState == BatteryState.full;
      } catch (e) {
        print('📊 Battery error: $e');
      }
      
      // Get connectivity
      String signal = 'Unknown';
      try {
        final connectivity = await Connectivity().checkConnectivity();
        if (connectivity.contains(ConnectivityResult.wifi)) {
          signal = 'WiFi';
        } else if (connectivity.contains(ConnectivityResult.mobile)) {
          signal = 'Mobile Data';
        } else if (connectivity.contains(ConnectivityResult.ethernet)) {
          signal = 'Ethernet';
        } else if (connectivity.contains(ConnectivityResult.none)) {
          signal = 'Offline';
        }
      } catch (e) {
        print('📊 Connectivity error: $e');
      }
      
      // Storage - simplified for now
      String storage = 'Available';
      try {
        final Directory appDir = Directory('/storage/emulated/0');
        if (await appDir.exists()) {
          // We can't easily get free space in pure Dart, 
          // but we can indicate storage is accessible
          storage = 'Accessible';
        }
      } catch (e) {
        print('📊 Storage error: $e');
      }
      
      final stats = {
        'battery': batteryLevel,
        'batteryCharging': isCharging,
        'signal': signal,
        'storage': storage,
      };
      
      _sendMessage!(MessageEnvelope(
        type: MessageType.deviceStats,
        messageId: const Uuid().v4(),
        timestamp: DateTime.now(),
        payload: stats,
      ));
      
      print('📊 Stats sent: $stats');
    } catch (e) {
      print('❌ Error gathering stats: $e');
    }
  }

  /// Force an immediate stats update
  Future<void> sendStatsNow() async {
    await _gatherAndSendStats();
  }

  /// Stop monitoring
  void stop() {
    _timer?.cancel();
    _timer = null;
    _sendMessage = null;
    print('📊 DeviceMonitorService stopped');
  }
}

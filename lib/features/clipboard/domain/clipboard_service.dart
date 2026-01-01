import 'dart:async';
import 'package:flutter/services.dart';
import '../../../core/utils/logger.dart';
import '../../../core/models/clipboard_message.dart';

class ClipboardService {
  static const Duration debounceDuration = Duration(milliseconds: 500);
  
  Timer? _debounceTimer;
  String? _lastSentContent;
  String? _lastReceivedContent;
  
  final Function(ClipboardMessage) onClipboardChanged;
  final String deviceId;
  final String deviceName;
  
  ClipboardService({
    required this.onClipboardChanged,
    required this.deviceId,
    required this.deviceName,
  });
  
  /// Monitor local clipboard and send changes
  void startMonitoring() {
    AppLogger.info('Clipboard monitoring started');
    // Note: clipboard_watcher doesn't work well on Android
    // For now, we'll implement manual sync via button
  }
  
  /// Send current clipboard content
  Future<void> sendClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final content = clipboardData?.text;
      
      if (content == null || content.isEmpty) {
        AppLogger.debug('Clipboard is empty, nothing to send');
        return;
      }
      
      // Prevent sending if it's what we just received
      if (content == _lastReceivedContent) {
        AppLogger.debug('Skipping send - content matches last received');
        return;
      }
      
      // Prevent duplicate sends
      if (content == _lastSentContent) {
        AppLogger.debug('Skipping send - content already sent');
        return;
      }
      
      // Debounce rapid changes
      _debounceTimer?.cancel();
      _debounceTimer = Timer(debounceDuration, () {
        _sendClipboardContent(content);
      });
      
    } catch (e) {
      AppLogger.error('Failed to read clipboard', e);
    }
  }
  
  void _sendClipboardContent(String content) {
    final message = ClipboardMessage(
      content: content,
      type: ClipboardMessage.detectType(content),
      timestamp: DateTime.now(),
      sourceDeviceId: deviceId,
      sourceDeviceName: deviceName,
    );
    
    _lastSentContent = content;
    onClipboardChanged(message);
    AppLogger.info('📋 Clipboard sent: ${message.type.name} (${content.length} chars)');
  }
  
  /// Receive clipboard content from remote device
  Future<void> receiveClipboard(ClipboardMessage message) async {
    try {
      // Prevent loop: don't apply if we just sent this
      if (message.content == _lastSentContent) {
        AppLogger.debug('Skipping receive - preventing loop');
        return;
      }
      
      await Clipboard.setData(ClipboardData(text: message.content));
      _lastReceivedContent = message.content;
      
      AppLogger.info('📋 Clipboard received: ${message.type.name} from ${message.sourceDeviceName}');
    } catch (e) {
      AppLogger.error('Failed to set clipboard', e);
    }
  }
  
  void dispose() {
    _debounceTimer?.cancel();
    AppLogger.info('Clipboard service disposed');
  }
}

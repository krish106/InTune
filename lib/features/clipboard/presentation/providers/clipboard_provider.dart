import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/clipboard_service.dart';
import '../../../core/models/clipboard_message.dart';
import '../../../core/models/device_info.dart';
import '../../../core/models/message_envelope.dart';
import '../../connection/presentation/providers/connection_provider.dart';
import '../../../core/utils/logger.dart';

class ClipboardState {
  final ClipboardMessage? lastMessage;
  final bool isEnabled;
  final String? error;
  
  ClipboardState({
    this.lastMessage,
    this.isEnabled = true,
    this.error,
  });
  
  ClipboardState copyWith({
    ClipboardMessage? lastMessage,
    bool? isEnabled,
    String? error,
  }) {
    return ClipboardState(
      lastMessage: lastMessage ?? this.lastMessage,
      isEnabled: isEnabled ?? this.isEnabled,
      error: error,
    );
  }
}

class ClipboardNotifier extends StateNotifier<ClipboardState> {
  final Ref ref;
  ClipboardService? _service;
  
  ClipboardNotifier(this.ref) : super(ClipboardState());
  
  void initialize() {
    final deviceInfo = ref.read(deviceInfoProvider);
    
    _service = ClipboardService(
      deviceId: deviceInfo.deviceId,
      deviceName: deviceInfo.deviceName,
      onClipboardChanged: _handleLocalClipboardChange,
    );
    
    _service!.startMonitoring();
    AppLogger.info('Clipboard provider initialized');
  }
  
  /// Handle local clipboard change - send to remote
  void _handleLocalClipboardChange(ClipboardMessage message) {
    try {
      final connectionNotifier = ref.read(connectionProvider.notifier);
      connectionNotifier.sendMessage(
        MessageType.clipboard,
        message.toPayload(),
      );
      
      state = state.copyWith(lastMessage: message);
    } catch (e) {
      AppLogger.error('Failed to send clipboard message', e);
      state = state.copyWith(error: e.toString());
    }
  }
  
  /// Handle remote clipboard change - apply locally
  void handleRemoteClipboard(Map<String, dynamic> payload) {
    try {
      final message = ClipboardMessage.fromPayload(payload);
      _service?.receiveClipboard(message);
      state = state.copyWith(lastMessage: message);
    } catch (e) {
      AppLogger.error('Failed to receive clipboard message', e);
      state = state.copyWith(error: e.toString());
    }
  }
  
  /// Manual clipboard send (button triggered)
  Future<void> syncClipboard() async {
    if (!state.isEnabled) return;
    await _service?.sendClipboard();
  }
  
  /// Toggle clipboard sync
  void toggleSync() {
    state = state.copyWith(isEnabled: !state.isEnabled);
    AppLogger.info('Clipboard sync ${state.isEnabled ? "enabled" : "disabled"}');
  }
  
  @override
  void dispose() {
    _service?.dispose();
    super.dispose();
  }
}

final clipboardProvider = StateNotifierProvider<ClipboardNotifier, ClipboardState>((ref) {
  final notifier = ClipboardNotifier(ref);
  notifier.initialize();
  return notifier;
});

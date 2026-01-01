import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import '../../domain/screen_capture_service.dart';
export '../../domain/screen_capture_service.dart' show CaptureQuality;
import '../../../../core/models/message_envelope.dart';
import '../../../connection/presentation/providers/connection_provider.dart';
import '../../../../core/utils/logger.dart';

class ScreenShareState {
  final bool isSharing;
  final CaptureQuality quality;
  final int framesSent;
  final int framesDropped;
  
  ScreenShareState({
    this.isSharing = false,
    this.quality = CaptureQuality.high,
    this.framesSent = 0,
    this.framesDropped = 0,
  });
  
  ScreenShareState copyWith({
    bool? isSharing,
    CaptureQuality? quality,
    int? framesSent,
    int? framesDropped,
  }) {
    return ScreenShareState(
      isSharing: isSharing ?? this.isSharing,
      quality: quality ?? this.quality,
      framesSent: framesSent ?? this.framesSent,
      framesDropped: framesDropped ?? this.framesDropped,
    );
  }
}

class ScreenShareNotifier extends StateNotifier<ScreenShareState> {
  final Ref ref;
  ScreenCaptureService? _captureService;
  
  ScreenShareNotifier(this.ref) : super(ScreenShareState());
  
  void initialize() {
    _captureService = ScreenCaptureService(
      onFrameCaptured: _handleFrameCaptured,
      onCaptureStopped: _handleCaptureStopped,
      isWebSocketBusy: null, // TODO: Implement buffer check
    );
  }
  
  void _handleFrameCaptured(Uint8List frameData, int frameNumber, int width, int height) {
    try {
      // Send frame via WebSocket
      final connectionNotifier = ref.read(connectionProvider.notifier);
      connectionNotifier.sendMessage(
        MessageEnvelope(
          type: MessageType.screenFrame,
          messageId: 'frame-$frameNumber',
          timestamp: DateTime.now(),
          payload: {
            'frameNumber': frameNumber,
            'width': width,
            'height': height,
            'quality': state.quality.index,
            'dataSize': frameData.length,
          },
        ),
      );
      
      // TODO: Send binary frame data
      // For now, we'll just count frames
      state = state.copyWith(framesSent: state.framesSent + 1);
      
    } catch (e) {
      AppLogger.error('Failed to send screen frame', e);
    }
  }
  
  void _handleCaptureStopped() {
    state = state.copyWith(isSharing: false);
    AppLogger.info('Screen sharing stopped');
  }
  
  Future<void> startSharing({int fps = 20}) async {
    if (state.isSharing) return;
    
    _captureService ??= ScreenCaptureService(
      onFrameCaptured: _handleFrameCaptured,
      onCaptureStopped: _handleCaptureStopped,
    );
    
    await _captureService!.startCapture(targetFPS: fps);
    state = state.copyWith(isSharing: true, framesSent: 0, framesDropped: 0);
    
    AppLogger.info('🎬 Screen sharing started at $fps FPS');
  }
  
  void stopSharing() {
    _captureService?.stopCapture();
    state = state.copyWith(isSharing: false);
  }
  
  void setQuality(CaptureQuality quality) {
    _captureService?.setQuality(quality);
    state = state.copyWith(quality: quality);
  }
  
  @override
  void dispose() {
    _captureService?.dispose();
    super.dispose();
  }
}

final screenShareProvider = StateNotifierProvider<ScreenShareNotifier, ScreenShareState>((ref) {
  return ScreenShareNotifier(ref);
});

import 'dart:async';
import 'dart:typed_data';
import 'package:screen_capturer/screen_capturer.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../../../core/utils/logger.dart';

enum CaptureQuality { low, medium, high }

class ScreenCaptureService {
  Timer? _captureTimer;
  bool _isCapturing = false;
  CaptureQuality _quality = CaptureQuality.high;
  
  // Frame stats
  int _droppedFrames = 0;
  int _sentFrames = 0;
  int _frameCounter = 0;
  DateTime? _lastFrameTime;
  
  // Callbacks
  final Function(Uint8List frameData, int frameNumber, int width, int height)? onFrameCaptured;
  final Function()? onCaptureStopped;
  final bool Function()? isWebSocketBusy;
  
  ScreenCaptureService({
    this.onFrameCaptured,
    this.onCaptureStopped,
    this.isWebSocketBusy,
  });
  
  /* 
   * Optimization: Use compute isolate for image processing to prevent UI jank.
   * Reduced default FPS to 10 for better stability.
   */
  Future<void> startCapture({int targetFPS = 10}) async {
    if (_isCapturing) {
      AppLogger.warning('Screen capture already running');
      return;
    }
    
    _isCapturing = true;
    _frameCounter = 0;
    _droppedFrames = 0;
    _sentFrames = 0;
    
    // Clamp FPS to reasonable limits
    final fps = targetFPS.clamp(1, 15); 
    final intervalMs = (1000 / fps).round();
    AppLogger.info('🎬 Starting optimized screen capture at $fps FPS (${intervalMs}ms interval)');
    
    _captureTimer = Timer.periodic(
      Duration(milliseconds: intervalMs),
      (_) => _captureAndSendFrame(),
    );
  }
  
  /// Capture and send frame with dropping logic
  Future<void> _captureAndSendFrame() async {
    if (!_isCapturing) return;
    
    try {
      if (isWebSocketBusy != null && isWebSocketBusy!()) {
        _droppedFrames++;
        return;
      }
      
      // Capture
      final captureResult = await ScreenCapturer.instance.capture(
        mode: CaptureMode.screen,
        imagePath: null,
        copyToClipboard: false,
      );
      
      if (captureResult == null || captureResult.imageBytes == null) {
        return;
      }
      
      // Process in Background Isolate
      final result = await compute(_processFrameInIsolate, _FrameRequest(
        rawBytes: captureResult.imageBytes!,
        quality: _quality,
      ));
      
      if (result == null) return;
      
      // Send
      _frameCounter++;
      _sentFrames++;
      _lastFrameTime = DateTime.now();
            
      onFrameCaptured?.call(result.jpegBytes, _frameCounter, result.width, result.height);
      
    } catch (e) {
      // Suppress logs to avoid spam
    }
  }
  
  // Independent static method for isolate
  static Future<_FrameResult?> _processFrameInIsolate(_FrameRequest request) async {
    try {
      final image = img.decodeImage(request.rawBytes);
      if (image == null) return null;
      
      int jpgQuality;
      img.Image processedImage;
      
      switch (request.quality) {
        case CaptureQuality.low:
          jpgQuality = 40;
          processedImage = img.copyResize(image, width: (image.width * 0.5).toInt());
          break;
        case CaptureQuality.medium:
          jpgQuality = 60;
          processedImage = img.copyResize(image, width: (image.width * 0.75).toInt());
          break;
        case CaptureQuality.high:
          jpgQuality = 80;
          processedImage = image; // Full size
          break;
      }
      
      final jpegBytes = img.encodeJpg(processedImage, quality: jpgQuality);
      return _FrameResult(
        jpegBytes: Uint8List.fromList(jpegBytes),
        width: processedImage.width,
        height: processedImage.height,
      );
    } catch (e) {
      return null;
    }
  }

  
  /// Change capture quality
  void setQuality(CaptureQuality quality) {
    _quality = quality;
    AppLogger.info('🎨 Capture quality changed to: ${quality.name}');
  }
  
  /// Stop screen capture
  void stopCapture() {
    if (!_isCapturing) return;
    
    _captureTimer?.cancel();
    _captureTimer = null;
    _isCapturing = false;
    
    AppLogger.info('🛑 Screen capture stopped. Final stats: Sent=$_sentFrames, Dropped=$_droppedFrames');
    onCaptureStopped?.call();
  }
  
  /// Get current stats
  Map<String, dynamic> getStats() {
    final dropRate = _sentFrames + _droppedFrames > 0
        ? (_droppedFrames / (_sentFrames + _droppedFrames) * 100)
        : 0.0;
    
    return {
      'isCapturing': _isCapturing,
      'sentFrames': _sentFrames,
      'droppedFrames': _droppedFrames,
      'dropRate': dropRate,
      'quality': _quality.name,
    };
  }
  
  bool get isCapturing => _isCapturing;
  CaptureQuality get currentQuality => _quality;
  
  void dispose() {
    stopCapture();
  }
}

class _FrameRequest {
  final Uint8List rawBytes;
  final CaptureQuality quality;
  _FrameRequest({required this.rawBytes, required this.quality});
}

class _FrameResult {
  final Uint8List jpegBytes;
  final int width;
  final int height;
  _FrameResult({required this.jpegBytes, required this.width, required this.height});
}

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/models/message_envelope.dart';
import '../../../connection/presentation/providers/connection_provider.dart';
import '../../../../core/theme/velocity_theme.dart';

class ScreenMirrorViewer extends ConsumerStatefulWidget {
  const ScreenMirrorViewer({super.key});

  @override
  ConsumerState<ScreenMirrorViewer> createState() => _ScreenMirrorViewerState();
}

class _ScreenMirrorViewerState extends ConsumerState<ScreenMirrorViewer> {
  Uint8List? _currentFrame;
  int _frameWidth = 1080;
  int _frameHeight = 1920;
  int _frameCount = 0;
  DateTime? _lastFrameTime;
  double _fps = 0;
  
  // Input scaling
  final GlobalKey _imageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Register frame handler
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(connectionProvider.notifier).registerMessageHandler(_handleMessage);
    });
  }
  
  Future<void> _handleMessage(MessageEnvelope message) async {
    if (message.type == MessageType.screenFrame) {
      if (!mounted) return;
      
      final payload = message.payload;
      
      // Update stats
      _frameCount++;
      final now = DateTime.now();
      if (_lastFrameTime != null) {
        final delta = now.difference(_lastFrameTime!).inMilliseconds;
        if (delta > 0) {
          _fps = 1000 / delta; 
        }
      }
      _lastFrameTime = now;
      
      // We need to handle the frame data.
      // Ideally, the binary data comes separately or base64 encoded in payload.
      // For now, let's assume valid frame data comes in a way we can display.
      // Note: Actual implementation would require binary handling.
      // Since we don't have the binary channel fully spec'd out yet, 
      // I will put a placeholder logic here for now.
      
      setState(() {
        // If we had the bytes, we'd update _currentFrame
        _frameWidth = payload['width'] ?? _frameWidth;
        _frameHeight = payload['height'] ?? _frameHeight;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Controls Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: VelocityTheme.cardBackground,
          child: Row(
            children: [
               const Icon(Icons.cast_connected, color: VelocityTheme.electricCyan),
               const SizedBox(width: 8),
               Text(
                 'Android Mirror',
                 style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
               ),
               const Spacer(),
               if (_fps > 0)
                 Text(
                   '${_fps.toStringAsFixed(1)} FPS',
                   style: GoogleFonts.robotoMono(color: Colors.greenAccent, fontSize: 12),
                 ),
               const SizedBox(width: 16),
               IconButton(
                 icon: const Icon(Icons.refresh, color: Colors.white70),
                 onPressed: () {
                   // Request refresh
                 },
                 tooltip: 'Refresh Stream',
               ),
            ],
          ),
        ),
        
        // Viewer Area
        Expanded(
          child: Center(
            child: GestureDetector(
              onTapUp: _handleTap,
              onPanStart: _handlePanStart,
              onPanEnd: _handlePanEnd,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24),
                  color: Colors.black,
                ),
                child: AspectRatio(
                  aspectRatio: _frameWidth / _frameHeight,
                  child: Stack(
                    key: _imageKey,
                    fit: StackFit.expand,
                    children: [
                      if (_currentFrame != null)
                        Image.memory(
                          _currentFrame!,
                          gaplessPlayback: true,
                          fit: BoxFit.contain,
                        )
                      else
                        const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.monitor, size: 64, color: Colors.white12),
                              SizedBox(height: 16),
                              Text(
                                'Waiting for video stream...',
                                style: TextStyle(color: Colors.white38),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Start "Screen Share" on Android',
                                style: TextStyle(color: VelocityTheme.electricCyan, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        
                      // Debug overlay for taps
                      // ...
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  void _handleTap(TapUpDetails details) {
    _sendInput('tap', details.localPosition);
  }
  
  Offset? _panStart;
  
  void _handlePanStart(DragStartDetails details) {
    _panStart = details.localPosition;
  }
  
  void _handlePanEnd(DragEndDetails details) {
    if (_panStart == null) return;
    
    // Calculate swipe vector
    // This is a simplified swipe. Real swipe needs start/end points normalized.
    // Since we don't have the end point easily in DragEndDetails without tracking update,
    // we'll skip complex swipe for this iteration and focus on taps.
    
    _panStart = null;
  }
  
  void _sendInput(String type, Offset position) {
    // Get image render box size
    final RenderBox? renderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    
    final size = renderBox.size;
    final normalizedX = position.dx / size.width;
    final normalizedY = position.dy / size.height;
    
    // Bounds check
    if (normalizedX < 0 || normalizedX > 1 || normalizedY < 0 || normalizedY > 1) return;
    
    print('🖱️ Sending input: $type at ($normalizedX, $normalizedY)');
    
    ref.read(connectionProvider.notifier).sendMessage(
      MessageEnvelope(
        type: MessageType.inputEvent,
        messageId: const Uuid().v4(),
        timestamp: DateTime.now(),
        payload: {
          'type': type, // 'tap'
          'x': normalizedX,
          'y': normalizedY,
        },
      ),
    );
    
    // Show visual feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tap sent: ${normalizedX.toStringAsFixed(2)}, ${normalizedY.toStringAsFixed(2)}'),
        duration: const Duration(milliseconds: 500),
      ),
    );
  }
}

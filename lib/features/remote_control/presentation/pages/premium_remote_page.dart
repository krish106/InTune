import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import '../../../../core/theme/velocity_theme.dart';
import '../../../../core/models/message_envelope.dart';
import '../../../connection/presentation/providers/connection_provider.dart';

class PremiumRemotePage extends ConsumerStatefulWidget {
  const PremiumRemotePage({super.key});

  @override
  ConsumerState<PremiumRemotePage> createState() => _PremiumRemotePageState();
}

class _PremiumRemotePageState extends ConsumerState<PremiumRemotePage> with SingleTickerProviderStateMixin {
  Offset? _touchPoint;
  Offset? _previousPoint;
  late AnimationController _pulseController;
  double _sensitivity = 1.5;
  DateTime _lastMoveTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  final FocusNode _keyboardFocus = FocusNode();
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _pulseController.dispose();
    _keyboardFocus.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _sendMessage(MessageType type, Map<String, dynamic> payload) {
    try {
      ref.read(connectionProvider.notifier).sendMessage(
        MessageEnvelope(
          type: type,
          messageId: const Uuid().v4(),
          timestamp: DateTime.now(),
          payload: payload,
        ),
      );
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              // Hidden TextField with KeyboardListener for Keyboard Input
              KeyboardListener(
                focusNode: _keyboardFocus,
                onKeyEvent: (event) {
                  if (event is KeyDownEvent) {
                    if (event.logicalKey == LogicalKeyboardKey.backspace) {
                      _sendMessage(
                        MessageType.inputEvent,
                        {'type': 'hotkey', 'key': 'BACKSPACE'},
                      );
                    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
                      _sendMessage(
                        MessageType.inputEvent,
                        {'type': 'hotkey', 'key': 'ENTER'},
                      );
                    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
                      _sendMessage(
                        MessageType.inputEvent,
                        {'type': 'hotkey', 'key': 'ESCAPE'},
                      );
                    }
                  }
                },
                child: Opacity(
                  opacity: 0.0,
                  child: SizedBox(
                    height: 1,
                    width: 1,
                    child: TextField(
                      controller: _textController,
                      autofocus: false,
                      autocorrect: false,
                      enableSuggestions: false,
                      keyboardType: TextInputType.text,
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          _sendMessage(
                              MessageType.inputEvent, 
                              {'type': 'text_input', 'text': value}
                          );
                          _textController.clear();
                        }
                      },
                    ),
                  ),
                ),
              ),
              
              // TRACKPAD + SCROLL STRIP
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    children: [
                      // Trackpad
                      Expanded(child: _buildTrackpad()),
                      const SizedBox(width: 8),
                      // Scroll Strip
                      _buildScrollStrip(constraints.maxHeight * 0.65),
                    ],
                  ),
                ),
              ),
              
              // CONTROL DECK - Fixed height based on available space
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: _buildControlDeck(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTrackpad() {
    return RepaintBoundary(
      child: GestureDetector(
        onPanStart: (details) {
          HapticFeedback.lightImpact();
          _touchPoint = details.localPosition;
          _previousPoint = details.localPosition;
          _lastMoveTime = DateTime.now();
          setState(() {}); // Only trigger rebuild on start
        },
        onPanUpdate: (details) {
          // Throttle: only update every 8ms (120fps max)
          final now = DateTime.now();
          if (now.difference(_lastMoveTime).inMilliseconds < 8) return;
          _lastMoveTime = now;
          
          final prevPoint = _touchPoint;
          _touchPoint = details.localPosition;

          if (prevPoint != null) {
            final dx = (details.localPosition.dx - prevPoint.dx) * _sensitivity;
            final dy = (details.localPosition.dy - prevPoint.dy) * _sensitivity;
            
            // Don't setState - just send message for performance
            _sendMessage(
              MessageType.inputEvent,
              {'type': 'mouse_move', 'dx': dx, 'dy': dy},
            );
          }
        },
        onPanEnd: (details) {
          _touchPoint = null;
          _previousPoint = null;
          setState(() {}); // Only trigger rebuild on end
        },
        onTap: () {
          HapticFeedback.mediumImpact();
          _sendMessage(
            MessageType.inputEvent,
            {'type': 'mouse_click', 'button': 'left'},
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: VelocityTheme.cardBackground.withOpacity(0.3),
            border: Border.all(
              color: VelocityTheme.electricCyan.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Stack(
                children: [
                  // Grid Background
                  CustomPaint(
                    painter: IsometricGridPainter(),
                    size: Size.infinite,
                  ),

                  // Center Hint Icon
                  Center(
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: 0.1 + (0.1 * _pulseController.value),
                          child: const Icon(
                            Icons.touch_app,
                            size: 48,
                            color: VelocityTheme.electricCyan,
                          ),
                        );
                      },
                    ),
                  ),

                  // Glowing Touch Point
                  if (_touchPoint != null)
                    Positioned(
                      left: _touchPoint!.dx - 30,
                      top: _touchPoint!.dy - 30,
                      child: _buildGlowingTouchEffect(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlowingTouchEffect() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            VelocityTheme.electricCyan.withOpacity(0.6),
            VelocityTheme.neonPurple.withOpacity(0.2),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Center(
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: VelocityTheme.electricCyan,
            boxShadow: [
              BoxShadow(
                color: VelocityTheme.electricCyan,
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScrollStrip(double height) {
    return GestureDetector(
      onPanUpdate: (details) {
        _sendMessage(
            MessageType.inputEvent,
            {'type': 'mouse_scroll', 'dy': details.delta.dy},
        );
      },
      child: Container(
        width: 32,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withOpacity(0.05),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.keyboard_arrow_up, color: Colors.white30, size: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.white30, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildControlDeck() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Sensitivity Slider
        Row(
          children: [
            const Icon(Icons.speed, size: 14, color: Colors.white54),
            const SizedBox(width: 6),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: VelocityTheme.electricCyan,
                  inactiveTrackColor: Colors.white10,
                  thumbColor: VelocityTheme.electricCyan,
                  overlayColor: VelocityTheme.electricCyan.withOpacity(0.2),
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                ),
                child: Slider(
                  value: _sensitivity,
                  min: 0.5,
                  max: 3.0,
                  onChanged: (val) => setState(() => _sensitivity = val),
                ),
              ),
            ),
            Text(
              '${_sensitivity.toStringAsFixed(1)}x',
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ],
        ),
        
        const SizedBox(height: 8),

        // 4 Buttons in a Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildMacroButton(Icons.keyboard, 'KEYBOARD', () {
              if (_keyboardFocus.hasFocus) {
                _keyboardFocus.unfocus();
              } else {
                _keyboardFocus.requestFocus();
                // Ensure keyboard shows up
                SystemChannels.textInput.invokeMethod('TextInput.show');
              }
            }),
            _buildMacroButton(Icons.volume_off, 'MUTE', () {
               _sendMessage(MessageType.mediaControl, {'action': 'MUTE'});
            }),
            _buildMacroButton(Icons.view_comfy, 'TASK VIEW', () {
               _sendMessage(MessageType.inputEvent, {'type': 'hotkey', 'key': 'WIN+TAB'});
            }),
            _buildMacroButton(Icons.close, 'CLOSE', () {
               _sendMessage(MessageType.inputEvent, {'type': 'hotkey', 'key': 'ALT+F4'});
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildMacroButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withOpacity(0.05),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: VelocityTheme.neonPurple, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white60,
                fontSize: 7,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class IsometricGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;

    const spacing = 40.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

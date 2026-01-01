import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/velocity_theme.dart';
import '../../../../core/models/connection_state.dart' as conn;
import '../../../../core/models/device_info.dart';
import '../../../../core/constants/network_constants.dart';
import '../providers/connection_provider.dart';

class PremiumRadarPage extends ConsumerStatefulWidget {
  const PremiumRadarPage({super.key});

  @override
  ConsumerState<PremiumRadarPage> createState() => _PremiumRadarPageState();
}

class _PremiumRadarPageState extends ConsumerState<PremiumRadarPage> with SingleTickerProviderStateMixin {
  late AnimationController _sonarController;
  final _ipController = TextEditingController();
  bool _showManualEntry = false;

  @override
  void initState() {
    super.initState();
    _sonarController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _sonarController.dispose();
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectionState = ref.watch(connectionProvider);
    final isConnected = connectionState.status == conn.ConnectionStatus.connected;
    final isConnecting = connectionState.status == conn.ConnectionStatus.connecting ||
                         connectionState.status == conn.ConnectionStatus.handshaking;

    return Stack(
      children: [
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isConnected) 
                  _buildConnectedState(connectionState) 
                else if (isConnecting)
                  _buildConnectingState()
                else 
                  _buildConnectionUI(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionUI() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Sonar Animation
        AnimatedBuilder(
          animation: _sonarController,
          builder: (context, child) {
            return CustomPaint(
              size: const Size(250, 250),
              painter: SonarPainter(_sonarController.value),
              child: const SizedBox(
                width: 250,
                height: 250,
                child: Center(
                  child: Icon(
                    Icons.wifi_tethering,
                    size: 64,
                    color: VelocityTheme.electricCyan,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        Text(
          'CONNECT TO PC',
          style: GoogleFonts.orbitron(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: VelocityTheme.electricCyan,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the IP shown on your Windows PC',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white54,
          ),
        ),
        const SizedBox(height: 32),
        
        // IP Entry Field
        Container(
          constraints: const BoxConstraints(maxWidth: 350),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: VelocityTheme.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: VelocityTheme.electricCyan.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              TextField(
                controller: _ipController,
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '192.168.1.x',
                  hintStyle: GoogleFonts.orbitron(
                    color: Colors.white.withOpacity(0.2),
                    fontSize: 28,
                  ),
                  border: InputBorder.none,
                  prefixIcon: const Icon(
                    Icons.wifi,
                    color: VelocityTheme.electricCyan,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.paste, color: Colors.white54),
                    onPressed: () async {
                      final data = await Clipboard.getData(Clipboard.kTextPlain);
                      if (data?.text != null) {
                        _ipController.text = data!.text!.trim();
                      }
                    },
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                onSubmitted: (_) => _connect(),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Connect Button
        GestureDetector(
          onTap: _connect,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  VelocityTheme.neonPurple,
                  VelocityTheme.electricCyan,
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: VelocityTheme.electricCyan.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.link, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  'CONNECT',
                  style: GoogleFonts.orbitron(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Instructions
        Container(
          constraints: const BoxConstraints(maxWidth: 350),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildInstruction('1', 'Open InTune on Windows'),
              const SizedBox(height: 8),
              _buildInstruction('2', 'Note the IP address shown'),
              const SizedBox(height: 8),
              _buildInstruction('3', 'Enter IP above and connect'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInstruction(String num, String text) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: VelocityTheme.electricCyan.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              num,
              style: GoogleFonts.orbitron(
                fontSize: 12,
                color: VelocityTheme.electricCyan,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white54,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectingState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(
          color: VelocityTheme.electricCyan,
          strokeWidth: 3,
        ),
        const SizedBox(height: 32),
        Text(
          'CONNECTING',
          style: GoogleFonts.orbitron(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: VelocityTheme.electricCyan,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Establishing secure link...',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }

  Widget _buildConnectedState(conn.ConnectionState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 800),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withOpacity(0.1),
                  border: Border.all(color: Colors.green.withOpacity(0.5), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 50,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(Icons.check_circle, size: 80, color: Colors.green),
              ),
            );
          },
        ),
        const SizedBox(height: 32),
        Text(
          'CONNECTED',
          style: GoogleFonts.orbitron(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.green,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Text(
            state.remoteDevice?.deviceName ?? 'Windows PC',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStatusChip(Icons.wifi, 'Connected'),
            const SizedBox(width: 16),
            _buildStatusChip(Icons.security, 'Secure'),
          ],
        ),
        const SizedBox(height: 32),
        TextButton.icon(
          onPressed: () {
            ref.read(connectionProvider.notifier).disconnect();
          },
          icon: const Icon(Icons.close, color: Colors.red),
          label: Text(
            'Disconnect',
            style: GoogleFonts.inter(color: Colors.red),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  void _connect() async {
    final ip = _ipController.text.trim();
    
    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the server IP address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Validate IP format
    final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
    if (!ipRegex.hasMatch(ip)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid IP address format'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    try {
      final deviceInfo = DeviceInfo(
        deviceId: 'android_${DateTime.now().millisecondsSinceEpoch}',
        deviceName: 'Android Device',
        role: DeviceRole.client,
        platform: PlatformType.android,
        appVersion: '1.0.0',
        osVersion: 'Android',
      );

      await ref.read(connectionProvider.notifier).connectToServer(
        ip,
        NetworkConstants.defaultPort,
        deviceInfo,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}

class SonarPainter extends CustomPainter {
  final double animationValue;
  SonarPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < 3; i++) {
      final rippleValue = (animationValue + (i * 0.33)) % 1.0;
      final radius = maxRadius * rippleValue;
      final opacity = (1.0 - rippleValue) * 0.5;

      final paint = Paint()
        ..color = VelocityTheme.electricCyan.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 + (2 * (1 - rippleValue));

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

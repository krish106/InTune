import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/velocity_theme.dart';
import '../../../../core/constants/network_constants.dart';

class PortalState extends ConsumerWidget {
  final String serverIP;
  
  const PortalState({
    super.key,
    required this.serverIP,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: FadeInUp(
          duration: const Duration(milliseconds: 600),
          child: _buildConnectionCard(context),
        ),
      ),
    );
  }
  
  Widget _buildConnectionCard(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 450),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: VelocityTheme.glowGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: VelocityTheme.electricCyan,
          width: 2,
        ),
        boxShadow: [
          VelocityTheme.cyanGlow,
          VelocityTheme.purpleGlow,
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: VelocityTheme.electricCyan.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: VelocityTheme.electricCyan.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.wifi_tethering,
              size: 64,
              color: VelocityTheme.electricCyan,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Title
          Text(
            'Server Running',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Enter this IP on your Android device',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white54,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Big IP Display
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: serverIP));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('IP address copied: $serverIP'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: VelocityTheme.electricCyan,
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              decoration: BoxDecoration(
                color: VelocityTheme.deepNavy,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: VelocityTheme.electricCyan,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: VelocityTheme.electricCyan.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    serverIP,
                    style: GoogleFonts.orbitron(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: VelocityTheme.electricCyan,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.copy_rounded,
                    color: VelocityTheme.electricCyan.withOpacity(0.7),
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Tap to copy',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white38,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Port Info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: VelocityTheme.cardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.settings_ethernet,
                  color: Colors.white54,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Port: ${NetworkConstants.defaultPort}',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Status indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Waiting for connection...',
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

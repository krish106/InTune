import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/velocity_theme.dart';
import '../../../connection/presentation/providers/connection_provider.dart';
import '../../../../core/models/message_envelope.dart';

class MediaControlPanel extends ConsumerWidget {
  const MediaControlPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: VelocityTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: VelocityTheme.electricCyan.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.music_note, color: VelocityTheme.electricCyan),
              const SizedBox(width: 8),
              Text(
                'Media Control',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMediaButton(
                icon: Icons.skip_previous,
                label: 'Previous',
                onPressed: () => _sendMediaCommand(ref, 'PREV'),
              ),
              _buildMediaButton(
                icon: Icons.play_arrow,
                label: 'Play/Pause',
                onPressed: () => _sendMediaCommand(ref, 'PLAY_PAUSE'),
                isPrimary: true,
              ),
              _buildMediaButton(
                icon: Icons.skip_next,
                label: 'Next',
                onPressed: () => _sendMediaCommand(ref, 'NEXT'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMediaButton(
                icon: Icons.volume_down,
                label: 'Vol -',
                onPressed: () => _sendMediaCommand(ref, 'VOL_DOWN'),
              ),
              _buildMediaButton(
                icon: Icons.volume_up,
                label: 'Vol +',
                onPressed: () => _sendMediaCommand(ref, 'VOL_UP'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMediaButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isPrimary
                ? VelocityTheme.electricCyan.withOpacity(0.2)
                : VelocityTheme.deepNavy,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPrimary
                  ? VelocityTheme.electricCyan
                  : Colors.white24,
            ),
          ),
          child: Icon(
            icon,
            color: isPrimary ? VelocityTheme.electricCyan : Colors.white70,
            size: 28,
          ),
        ),
      ),
    );
  }

  void _sendMediaCommand(WidgetRef ref, String action) {
    ref.read(connectionProvider.notifier).sendMessage(
      MessageType.mediaControl,
      {'action': action},
    );
  }
}

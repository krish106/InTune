import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/speed_calculator.dart';

class TransferProgressCard extends StatelessWidget {
  final String fileName;
  final TransferMetrics metrics;
  final VoidCallback? onCancel;

  const TransferProgressCard({
    super.key,
    required this.fileName,
    required this.metrics,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      blur: 10,
      opacity: 0.1,
      borderRadius: BorderRadius.circular(16),
      border: Border.fromBorderSide(BorderSide(color: Colors.white.withOpacity(0.1))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.description, color: Colors.white70, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fileName,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onCancel != null)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                    onPressed: onCancel,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: metrics.percentage,
                backgroundColor: Colors.white10,
                color: Colors.cyanAccent,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 12),
            
            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatBadge(
                  icon: Icons.percent,
                  text: '${(metrics.percentage * 100).toInt()}%',
                ),
                _buildStatBadge(
                  icon: Icons.speed,
                  text: metrics.speedStr,
                  color: Colors.cyanAccent,
                ),
                _buildStatBadge(
                  icon: Icons.timer,
                  text: metrics.etrStr,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatBadge({required IconData icon, required String text, Color color = Colors.white70}) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color.withOpacity(0.7)),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.robotoMono(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

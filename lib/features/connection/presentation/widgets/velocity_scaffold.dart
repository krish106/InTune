import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/velocity_theme.dart';

class VelocityScaffold extends StatefulWidget {
  final Widget body;
  final int currentIndex;
  final Function(int) onTabChanged;

  const VelocityScaffold({
    super.key,
    required this.body,
    required this.currentIndex,
    required this.onTabChanged,
  });

  @override
  State<VelocityScaffold> createState() => _VelocityScaffoldState();
}

class _VelocityScaffoldState extends State<VelocityScaffold> with SingleTickerProviderStateMixin {
  late AnimationController _bgController;
  late Animation<Alignment> _topAlignmentAnimation;
  late Animation<Alignment> _bottomAlignmentAnimation;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat(reverse: true);

    _topAlignmentAnimation = TweenSequence<Alignment>([
      TweenSequenceItem(tween: Tween(begin: Alignment.topLeft, end: Alignment.topRight), weight: 1),
      TweenSequenceItem(tween: Tween(begin: Alignment.topRight, end: Alignment.bottomRight), weight: 1),
      TweenSequenceItem(tween: Tween(begin: Alignment.bottomRight, end: Alignment.bottomLeft), weight: 1),
      TweenSequenceItem(tween: Tween(begin: Alignment.bottomLeft, end: Alignment.topLeft), weight: 1),
    ]).animate(_bgController);

    _bottomAlignmentAnimation = TweenSequence<Alignment>([
      TweenSequenceItem(tween: Tween(begin: Alignment.bottomRight, end: Alignment.bottomLeft), weight: 1),
      TweenSequenceItem(tween: Tween(begin: Alignment.bottomLeft, end: Alignment.topLeft), weight: 1),
      TweenSequenceItem(tween: Tween(begin: Alignment.topLeft, end: Alignment.topRight), weight: 1),
      TweenSequenceItem(tween: Tween(begin: Alignment.topRight, end: Alignment.bottomRight), weight: 1),
    ]).animate(_bgController);
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: _topAlignmentAnimation.value,
                end: _bottomAlignmentAnimation.value,
                colors: [
                  VelocityTheme.deepNavy,
                  const Color(0xFF1E293B),
                  const Color(0xFF0F172A),
                ],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(child: widget.body),
      ),
      bottomNavigationBar: _buildGlassBottomNav(),
    );
  }

  Widget _buildGlassBottomNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: VelocityTheme.electricCyan.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            height: 75,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(0, Icons.radar, 'RADAR'),
                _buildNavItem(1, Icons.dashboard_rounded, 'DASHBOARD'),
                _buildNavItem(2, Icons.gamepad, 'REMOTE'),
                _buildNavItem(3, Icons.folder_open, 'FILES'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = widget.currentIndex == index;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTabChanged(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 12, 
          vertical: 12
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? VelocityTheme.electricCyan.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isSelected 
              ? Border.all(color: VelocityTheme.electricCyan.withOpacity(0.3), width: 1)
              : Border.all(color: Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? VelocityTheme.electricCyan : Colors.white54,
              size: 26,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.orbitron(
                  color: VelocityTheme.electricCyan,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/theme/velocity_theme.dart';

enum NavSection { home, transfers, settings }

class VelocityNavigationRail extends StatelessWidget {
  final NavSection selectedSection;
  final Function(NavSection) onSectionChanged;
  final bool isServerActive;
  
  const VelocityNavigationRail({
    super.key,
    required this.selectedSection,
    required this.onSectionChanged,
    this.isServerActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            VelocityTheme.cardBackground.withOpacity(0.5),
            VelocityTheme.cardBackground.withOpacity(0.3),
          ],
        ),
        border: Border(
          right: BorderSide(
            color: VelocityTheme.electricCyan.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          
          // Logo
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: VelocityTheme.cyberGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [VelocityTheme.cyanGlow],
            ),
            child: const Icon(Icons.flash_on, color: Colors.white),
          ),
          
          const SizedBox(height: 48),
          
          // Navigation Items
          _buildNavItem(
            emoji: '🏠',
            section: NavSection.home,
            label: 'Home',
          ),
          _buildNavItem(
            emoji: '📂',
            section: NavSection.transfers,
            label: 'Files',
          ),

          _buildNavItem(
            emoji: '⚙️',
            section: NavSection.settings,
            label: 'Settings',
          ),
          
          const Spacer(),
          
          // Server Status Indicator
          _buildStatusIndicator(),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  Widget _buildNavItem({
    required String emoji,
    required NavSection section,
    required String label,
  }) {
    final isSelected = selectedSection == section;
    
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: () => onSectionChanged(section),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected 
                ? VelocityTheme.electricCyan.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            emoji,
            style: TextStyle(
              fontSize: 24,
              color: isSelected 
                  ? Colors.white
                  : Colors.white54,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatusIndicator() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isServerActive 
                  ? Colors.green
                  : Colors.grey,
              shape: BoxShape.circle,
              boxShadow: isServerActive ? [
                BoxShadow(
                  color: Colors.green.withOpacity(0.6),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ] : null,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isServerActive ? 'Active' : 'Offline',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

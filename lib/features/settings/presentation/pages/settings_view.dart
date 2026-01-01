import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/theme/velocity_theme.dart';
import '../../../file_transfer/data/transfer_history_service.dart';

/// Settings View for VelocityLink
class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final TextEditingController _deviceNameController = TextEditingController();
  String _downloadPath = 'Loading...';
  bool _autoConnect = true;
  bool _showNotifications = true;
  bool _soundEnabled = true;
  
  // Hive box for settings
  Box? _settingsBox;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      _settingsBox = await Hive.openBox('app_settings');
      
      setState(() {
        _deviceNameController.text = _settingsBox?.get('deviceName', defaultValue: 'Windows PC') ?? 'Windows PC';
        _autoConnect = _settingsBox?.get('autoConnect', defaultValue: true) ?? true;
        _showNotifications = _settingsBox?.get('showNotifications', defaultValue: true) ?? true;
        _soundEnabled = _settingsBox?.get('soundEnabled', defaultValue: true) ?? true;
      });
      
      // Load download path
      final path = await TransferHistoryService.getDownloadPath();
      setState(() => _downloadPath = path);
    } catch (e) {
      print('❌ Error loading settings: $e');
    }
  }

  Future<void> _saveDeviceName(String value) async {
    await _settingsBox?.put('deviceName', value);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Device name saved')),
    );
  }

  Future<void> _changeDownloadPath() async {
    final newPath = await TransferHistoryService.pickDownloadDirectory();
    if (newPath != null) {
      setState(() => _downloadPath = newPath);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download path changed to: $newPath')),
      );
    }
  }

  Future<void> _toggleSetting(String key, bool value) async {
    await _settingsBox?.put(key, value);
    setState(() {
      switch (key) {
        case 'autoConnect':
          _autoConnect = value;
          break;
        case 'showNotifications':
          _showNotifications = value;
          break;
        case 'soundEnabled':
          _soundEnabled = value;
          break;
      }
    });
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'SETTINGS',
            style: GoogleFonts.orbitron(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 32),
          
          // Device Section
          _buildSectionHeader('📱 Device'),
          const SizedBox(height: 16),
          _buildCard([
            _buildTextField(
              label: 'Device Name',
              controller: _deviceNameController,
              hint: 'Enter a name for this PC',
              onSubmitted: _saveDeviceName,
            ),
          ]),
          
          const SizedBox(height: 24),
          
          // Storage Section
          _buildSectionHeader('📁 Storage'),
          const SizedBox(height: 16),
          _buildCard([
            _buildPathSelector(
              label: 'Download Location',
              path: _downloadPath,
              onTap: _changeDownloadPath,
            ),
          ]),
          
          const SizedBox(height: 24),
          
          // Connection Section
          _buildSectionHeader('🔗 Connection'),
          const SizedBox(height: 16),
          _buildCard([
            _buildToggle(
              label: 'Auto-connect to last device',
              value: _autoConnect,
              onChanged: (v) => _toggleSetting('autoConnect', v),
            ),
          ]),
          
          const SizedBox(height: 24),
          
          // Notifications Section
          _buildSectionHeader('🔔 Notifications'),
          const SizedBox(height: 16),
          _buildCard([
            _buildToggle(
              label: 'Show notifications',
              value: _showNotifications,
              onChanged: (v) => _toggleSetting('showNotifications', v),
            ),
            const Divider(color: Colors.white12),
            _buildToggle(
              label: 'Sound effects',
              value: _soundEnabled,
              onChanged: (v) => _toggleSetting('soundEnabled', v),
            ),
          ]),
          
          const SizedBox(height: 32),
          
          // About Section
          _buildSectionHeader('ℹ️ About'),
          const SizedBox(height: 16),
          _buildCard([
            _buildInfoRow('Version', '1.0.0'),
            const Divider(color: Colors.white12),
            _buildInfoRow('Build', 'Phase 8 - Functionality Patch'),
          ]),
          
          const SizedBox(height: 32),
          
          // Clear Data Button
          Center(
            child: OutlinedButton.icon(
              onPressed: _showClearDataDialog,
              icon: const Text('🗑️'),
              label: const Text('Clear Transfer History'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.orbitron(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: VelocityTheme.electricCyan,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: VelocityTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required Function(String) onSubmitted,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
          ),
        ),
        Expanded(
          flex: 3,
          child: TextField(
            controller: controller,
            style: GoogleFonts.inter(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(color: Colors.white38),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onSubmitted: onSubmitted,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Text('💾'),
          onPressed: () => onSubmitted(controller.text),
          tooltip: 'Save',
        ),
      ],
    );
  }

  Widget _buildPathSelector({
    required String label,
    required String path,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
          ),
        ),
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              path,
              style: GoogleFonts.robotoMono(fontSize: 12, color: Colors.white70),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: VelocityTheme.electricCyan,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text('Change'),
        ),
      ],
    );
  }

  Widget _buildToggle({
    required String label,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: VelocityTheme.electricCyan,
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
          ),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VelocityTheme.cardBackground,
        title: Text(
          'Clear Transfer History?',
          style: GoogleFonts.orbitron(color: Colors.white),
        ),
        content: Text(
          'This will delete all transfer logs. This action cannot be undone.',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await TransferHistoryService.clearAllLogs();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Transfer history cleared')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

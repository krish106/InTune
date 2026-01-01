import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/velocity_theme.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../../../../features/file_transfer/data/transfer_history_service.dart';
import '../../../../core/models/device_info.dart';
import '../../../../features/connection/presentation/providers/connection_provider.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  final VoidCallback onFinish;
  const OnboardingPage({super.key, required this.onFinish});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  int _currentPage = 0;
  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentName = ref.read(deviceInfoProvider).deviceName;
      _nameController.text = currentName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VelocityTheme.deepNavy,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), 
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _buildWelcomePage(),
                  if (Platform.isAndroid) _buildPermissionsPage(),
                  if (Platform.isWindows) _buildWindowsInfoPage(),
                  _buildIdentityPage(),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return _buildSlide(
      icon: Icons.rocket_launch,
      title: 'Welcome to VelocityLink',
      description: 'The ultra-fast, local-first connectivity suite for all your devices.\n\nFile Transfer • Remote Control • Screen Mirroring',
    );
  }

  Widget _buildWindowsInfoPage() {
     return _buildSlide(
      icon: Icons.security,
      title: 'Firewall Setup',
      description: 'VelocityLink requires high-performance network access.\n\nThe installer has already configured the Firewall rules for you.',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
        child: const Text('✅ Firewall Rule Added', style: TextStyle(color: Colors.greenAccent)),
      ),
    );
  }

  Widget _buildPermissionsPage() {
    return _buildSlide(
      icon: Icons.lock_open,
      title: 'Grant Permissions',
      description: 'To function correctly, we need access to:',
      child: Column(
        children: [
            _buildPermItem('Storage', 'Send & Receive files', Icons.folder),
            _buildPermItem('Nearby Devices', 'Discover peers', Icons.wifi_tethering), 
            _buildPermItem('Notification', 'Keep connection alive', Icons.notifications),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _requestPermissions,
              style: ElevatedButton.styleFrom(
                backgroundColor: VelocityTheme.electricCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: Text(_permissionsGranted ? 'Permissions Granted ✅' : 'Grant All Permissions'),
            )
        ],
      )
    );
  }

  Widget _buildPermItem(String title, String subtitle, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54)),
    );
  }

  Future<void> _requestPermissions() async {
    // Request critical permissions
    await [
      Permission.manageExternalStorage, // Android 11+
      Permission.storage, // Legacy
      Permission.nearbyWifiDevices,
      Permission.notification,
    ].request();

    setState(() {
      _permissionsGranted = true;
    });
  }

  Widget _buildIdentityPage() {
    return _buildSlide(
      icon: Icons.badge,
      title: 'Who are you?',
      description: 'This name will be visible to other devices.',
      child: TextField(
        controller: _nameController,
        style: const TextStyle(color: Colors.white, fontSize: 18),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white10,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          hintText: 'e.g. John\'s Phone',
          hintStyle: const TextStyle(color: Colors.white30),
        ),
      ),
    );
  }

  Widget _buildSlide({required IconData icon, required String title, required String description, Widget? child}) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 80, color: VelocityTheme.electricCyan),
              const SizedBox(height: 32),
              Text(title, style: GoogleFonts.orbitron(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Text(description, style: GoogleFonts.inter(fontSize: 16, color: Colors.white70), textAlign: TextAlign.center),
              if (child != null) ...[
                const SizedBox(height: 32),
                child,
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final isLastPage = _currentPage == 2; 
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Dots
          Row(
            children: List.generate(3, (index) => Container(
              margin: const EdgeInsets.only(right: 8),
              width: 8, height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentPage == index ? VelocityTheme.electricCyan : Colors.white24,
              ),
            )),
          ),
          ElevatedButton(
            onPressed: () {
              if (_currentPage < 2) {
                 if (Platform.isAndroid && _currentPage == 1 && !_permissionsGranted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please grant permissions to continue')));
                    return; 
                 }
                 _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
              } else {
                 _finishOnboarding();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: VelocityTheme.electricCyan,
              foregroundColor: Colors.black,
            ),
            child: Text(isLastPage ? 'Get Started 🚀' : 'Next'),
          )
        ],
      ),
    );
  }
  
  void _finishOnboarding() async {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      final notifier = ref.read(deviceInfoProvider.notifier);
      final current = ref.read(deviceInfoProvider);
      
      notifier.state = DeviceInfo( // Manually copy
        deviceId: current.deviceId,
        deviceName: name,
        role: current.role,
        platform: current.platform,
        appVersion: current.appVersion,
        osVersion: current.osVersion,
      );
      
      await TransferHistoryService.settingsBox?.put('device_name', name);
    }
    
    await TransferHistoryService.setFirstRunCompleted();
    
    widget.onFinish();
  }
}

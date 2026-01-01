import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/connection/presentation/screens/premium_host_screen.dart';
import 'features/file_transfer/data/transfer_history_service.dart';
import 'core/theme/velocity_theme.dart';

import 'dart:io';
import 'package:window_manager/window_manager.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'features/system_integration/system_tray_manager.dart';
import 'features/onboarding/presentation/pages/onboarding_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Window Manager
  await windowManager.ensureInitialized();
  
  // Initialize Launch at Startup
  LaunchAtStartup.instance.setup(
    appName: 'VelocityLink',
    appPath: Platform.resolvedExecutable,
  );
  await LaunchAtStartup.instance.enable();

  // Initialize System Tray
  // Note: SystemTrayManager implementation should exist at features/system_integration/system_tray_manager.dart
  // I noticed I used 'sys_integration' in import above, let me correct it if wrong.
  // Actually I created it in 'features/system_integration'. 
  // I will use correct import in this tool call.
  
  // Initialize Hive
  await TransferHistoryService.init();
  
  runApp(const ProviderScope(child: VelocityLinkHostApp()));
}

class VelocityLinkHostApp extends StatelessWidget {
  const VelocityLinkHostApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VelocityLink Host',
      debugShowCheckedModeBanner: false,
      theme: VelocityTheme.darkTheme,
      home: const WindowsRootWrapper(),
    );
  }
}

class WindowsRootWrapper extends StatefulWidget {
  const WindowsRootWrapper({super.key});

  @override
  State<WindowsRootWrapper> createState() => _WindowsRootWrapperState();
}

class _WindowsRootWrapperState extends State<WindowsRootWrapper> with WindowListener {
  bool _isFirstRun = TransferHistoryService.isFirstRun;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _initSystemTray();
    _initWindow();
  }
  
  void _initSystemTray() async {
    await SystemTrayManager().initSystemTray();
  }
  
  void _initWindow() async {
    await windowManager.setPreventClose(true); // Default to minimize
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() async {
    bool _isPreventClose = await windowManager.isPreventClose();
    if (_isPreventClose) {
      await windowManager.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFirstRun) {
      return OnboardingPage(onFinish: () {
        setState(() {
          _isFirstRun = false;
        });
      });
    }
    return const PremiumHostScreen();
  }
}

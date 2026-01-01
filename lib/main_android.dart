import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intune/core/theme/velocity_theme.dart';
import 'package:intune/features/connection/presentation/widgets/velocity_scaffold.dart';
import 'package:intune/features/connection/presentation/pages/premium_radar_page.dart';
import 'package:intune/features/remote_control/presentation/pages/premium_remote_page.dart';
import 'package:intune/features/dashboard/presentation/pages/premium_dashboard_page.dart';
import 'package:intune/features/file_transfer/presentation/pages/file_transfer_dashboard.dart';
import 'package:intune/features/file_transfer/data/transfer_history_service.dart';
import 'features/onboarding/presentation/pages/onboarding_page.dart';
import 'features/system_integration/android_background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Background Service
  await AndroidBackgroundService.initializeService();
  
  // Initialize Hive for transfer history
  await TransferHistoryService.init();
  
  runApp(const ProviderScope(child: VelocityPremiumApp()));
}

class VelocityPremiumApp extends StatelessWidget {
  const VelocityPremiumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VelocityLink',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: VelocityTheme.deepNavy,
        primaryColor: VelocityTheme.electricCyan,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
      ),
      home: const AndroidRootWrapper(),
    );
  }
}

class AndroidRootWrapper extends StatefulWidget {
  const AndroidRootWrapper({super.key});

  @override
  State<AndroidRootWrapper> createState() => _AndroidRootWrapperState();
}

class _AndroidRootWrapperState extends State<AndroidRootWrapper> {
  bool _isFirstRun = TransferHistoryService.isFirstRun;

  @override
  Widget build(BuildContext context) {
    if (_isFirstRun) {
      return OnboardingPage(onFinish: () {
        setState(() {
          _isFirstRun = false;
        });
      });
    }
    return const PremiumHomeWrapper();
  }
}

class PremiumHomeWrapper extends StatefulWidget {
  const PremiumHomeWrapper({super.key});

  @override
  State<PremiumHomeWrapper> createState() => _PremiumHomeWrapperState();
}

class _PremiumHomeWrapperState extends State<PremiumHomeWrapper> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const PremiumRadarPage(),
    const PremiumDashboardPage(),
    const PremiumRemotePage(),
    const FileTransferDashboard(),  // Replaced placeholder with actual dashboard
  ];

  @override
  void initState() {
    super.initState();
    // Force portrait and transparent status bar
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return VelocityScaffold(
      currentIndex: _currentIndex,
      onTabChanged: (index) {
        setState(() => _currentIndex = index);
      },
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _pages[_currentIndex],
      ),
    );
  }
}

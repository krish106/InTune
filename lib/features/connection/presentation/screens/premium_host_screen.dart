import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../file_transfer/data/transfer_history_service.dart';
import '../../../file_transfer/data/models/transfer_log.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/connection_state.dart' as conn;
import '../../../../core/models/device_info.dart';
import '../../../../core/theme/velocity_theme.dart';

import '../providers/connection_provider.dart';
import '../../../../core/constants/network_constants.dart';
import '../../../network_discovery/data/datasources/hotspot_info_detector.dart';
import '../widgets/velocity_navigation_rail.dart';
import '../widgets/portal_state.dart';


import '../../../remote_control/data/windows_input_service.dart';
import '../../../../core/models/message_envelope.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';
import '../widgets/command_center_view.dart';
import '../../../file_transfer/presentation/pages/file_transfer_dashboard.dart';
import '../../../settings/presentation/pages/settings_view.dart';
import '../../../screen_share/presentation/providers/screen_share_provider.dart';
import '../../../screen_mirror/presentation/widgets/screen_mirror_viewer.dart';
import '../../../remote_file_system/presentation/widgets/remote_explorer_view.dart';

class PremiumHostScreen extends ConsumerStatefulWidget {
  const PremiumHostScreen({super.key});

  @override
  ConsumerState<PremiumHostScreen> createState() => _PremiumHostScreenState();
}

class _PremiumHostScreenState extends ConsumerState<PremiumHostScreen> {
  String? _serverIP;
  Map<String, String?>? _wifiCreds;
  NavSection _selectedSection = NavSection.home;
  final _inputService = WindowsInputService();
  Timer? _clipboardTimer;
  String? _lastClipboardContent;

  // File Transfer State
  IOSink? _currentFileSink;
  String? _currentFileName;
  int _receivedBytes = 0;
  int _totalBytes = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startServer();
      _startClipboardPolling();
    });
  }

  @override
  void dispose() {
    _clipboardTimer?.cancel();
    _currentFileSink?.close();
    super.dispose();
  }

  void _startClipboardPolling() {
    _clipboardTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
       if (!mounted) return;
       try {
         final data = await Clipboard.getData(Clipboard.kTextPlain);
         if (data?.text != null && data!.text != _lastClipboardContent) {
           _lastClipboardContent = data.text;
           // Push to client if connected
           final connectionState = ref.read(connectionProvider);
           if (connectionState.status == conn.ConnectionStatus.connected) {
             print('📋 Auto-sending clipboard update: ${_lastClipboardContent!.length} chars');
             ref.read(connectionProvider.notifier).sendMessage(
                MessageEnvelope(
                  type: MessageType.clipboard,
                  messageId: const Uuid().v4(),
                  timestamp: DateTime.now(),
                  payload: {'content': _lastClipboardContent},
                ),
             );
           }
         }
       } catch (e) {
         // Ignore clipboard errors
       }
    });
  }

  String? _currentFilePath;  // Track current file path for logging

  Future<void> _handleFileTransferMessage(Map<String, dynamic> payload) async {
    final action = payload['action'] as String?;
    
    if (action == 'header') {
      final fileName = payload['fileName'] as String;
      final fileSize = payload['fileSize'] as int;
      _currentFileName = fileName;
      _totalBytes = fileSize;
      _receivedBytes = 0;
      
      try {
        // Use custom download path from settings
        final downloadPath = await TransferHistoryService.getDownloadPath();
        _currentFilePath = p.join(downloadPath, fileName);
        print('📂 Receiving file to: $_currentFilePath');
        
        final file = File(_currentFilePath!);
        _currentFileSink = file.openWrite();
      } catch (e) {
        print('❌ Error creating file: $e');
      }
      
    } else if (action == 'chunk') {
      if (_currentFileSink != null) {
        final data = payload['data'] as String;
        final bytes = base64Decode(data);
        _currentFileSink!.add(bytes);
        _receivedBytes += bytes.length;
        
        if (_receivedBytes % (1024 * 1024) == 0) {
           print('📥 Progress: ${(_receivedBytes / 1024 / 1024).toStringAsFixed(1)} MB / ${(_totalBytes / 1024 / 1024).toStringAsFixed(1)} MB');
        }
      }
      
    } else if (action == 'end') {
      print('✅ File Transfer Complete: $_currentFileName');
      await _currentFileSink?.flush();
      await _currentFileSink?.close();
      _currentFileSink = null;
      
      // Log to Transfer History
      if (_currentFileName != null && _currentFilePath != null) {
        await TransferHistoryService.addLog(
          fileName: _currentFileName!,
          filePath: _currentFilePath!,
          fileSize: _totalBytes,
          direction: TransferDirection.received,
        );
      }
      
      // Notify UI
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('File Received: $_currentFileName')));
      }
    }
  }

  Future<void> _startServer() async {
    try {
      print('🚀 Starting server...');
      final deviceInfo = ref.read(deviceInfoProvider);
      print('📱 Device info: ${deviceInfo.deviceName}');
      
      final wifiCreds = await HotspotInfoDetector.getHotspotCredentials();
      print('📡 WiFi creds: $wifiCreds');
      
      // Register Message Handler for Remote Control & Files
      ref.read(connectionProvider.notifier).registerMessageHandler((message) async {
        if (message.type == MessageType.inputEvent) {
          print('🎮 PremiumHostScreen handling InputEvent');
          _inputService.handleInput(message.payload);
        } else if (message.type == MessageType.mediaControl) {
          _inputService.handleMediaControl(message.payload);
        } else if (message.type == MessageType.fileTransfer) {
           await _handleFileTransferMessage(message.payload);
        } else if (message.type == MessageType.clipboard) {
          final incomingContent = message.payload['content'] as String?;
          
          if (incomingContent != null && incomingContent != 'Sync Request') {
            // SET Operation (from Phone)
            // Need to avoid infinite loop -> update _lastClipboardContent
            if (incomingContent != _lastClipboardContent) {
               _lastClipboardContent = incomingContent;
               await Clipboard.setData(ClipboardData(text: incomingContent));
               print('📋 Clipboard updated from client');
                // Notify user
               if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clipboard Synced from Phone')));
               }
            }
          } else {
             // GET Operation (Sync Request) - handled by Poller or Manual check
             final data = await Clipboard.getData(Clipboard.kTextPlain);
             if (data?.text != null) {
               ref.read(connectionProvider.notifier).sendMessage(
                 MessageEnvelope(
                   type: MessageType.clipboard,
                   messageId: const Uuid().v4(),
                   timestamp: DateTime.now(),
                   payload: {'content': data!.text},
                 ),
               );
             }
          }
        }
      });

      final ip = await ref.read(connectionProvider.notifier).startServer(deviceInfo);
      print('✅ Server started on IP: $ip');

      if (mounted) {
        setState(() {
          _serverIP = ip;
          _wifiCreds = wifiCreds;
        });
        print('✨ UI updated with IP: $_serverIP');
      }
    } catch (e, stackTrace) {
      print('❌ Error starting server: $e');
      print('Stack trace: $stackTrace');
      
      if (mounted) {
        setState(() {
          _serverIP = 'error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectionState = ref.watch(connectionProvider);
    final deviceInfo = ref.watch(deviceInfoProvider);

    return Scaffold(
      backgroundColor: VelocityTheme.deepNavy,
      body: Row(
        children: [
          // Navigation Rail
          VelocityNavigationRail(
            selectedSection: _selectedSection,
            onSectionChanged: (section) {
              setState(() {
                _selectedSection = section;
              });
            },
            isServerActive: connectionState.status != conn.ConnectionStatus.disconnected,
          ),
          
          // Main Content Area
          Expanded(
            child: _buildMainContent(connectionState, deviceInfo),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(conn.ConnectionState connectionState, DeviceInfo deviceInfo) {
    if (_serverIP == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: VelocityTheme.electricCyan,
            ),
            SizedBox(height: 24),
            Text(
              'Starting server...',
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      );
    }
    
    // Handle error state
    if (_serverIP == 'error') {
      return Center(
        child: Text(
          'Error starting server\nCheck console for details',
          style: const TextStyle(color: Colors.red, fontSize: 18),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Show content based on current navigation section
    if (_selectedSection == NavSection.home) {
      // HOME TAB: Show Portal or Command Center
      if (connectionState.status == conn.ConnectionStatus.connected && 
          connectionState.remoteDevice != null) {
        return _buildCommandCenter(connectionState);
      } else {
        return PortalState(
          serverIP: _serverIP!,
        );
      }
    }
    
    // OTHER TABS: Show coming soon placeholders
    switch (_selectedSection) {
      case NavSection.transfers:
        return _buildTransfersView();
        

      case NavSection.settings:
        return _buildSettingsView();
        
      default:
        return PortalState(serverIP: _serverIP!);
    }
  }

  Widget _buildCommandCenter(conn.ConnectionState connectionState) {
    return CommandCenterView(connectionState: connectionState);
  }
  
  Widget _buildTransfersView() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: VelocityTheme.cardBackground,
            child: const TabBar(
              indicatorColor: VelocityTheme.electricCyan,
              labelColor: VelocityTheme.electricCyan,
              unselectedLabelColor: Colors.white60,
              tabs: [
                Tab(icon: Icon(Icons.history), text: 'History'),
                Tab(icon: Icon(Icons.storage), text: 'Phone Storage'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              physics: NeverScrollableScrollPhysics(), // Prevent swipe conflict with grid
              children: [
                FileTransferDashboard(),
                RemoteExplorerView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  



  
  Widget _buildSettingsView() {
    return const SettingsView();
  }
}

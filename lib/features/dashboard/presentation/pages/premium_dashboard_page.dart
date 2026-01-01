import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/velocity_theme.dart';
import '../../../../core/models/message_envelope.dart';
import '../../../connection/presentation/providers/connection_provider.dart';
import '../../../device_stats/data/device_monitor_service.dart';
import '../../../remote_control/data/remote_command_service.dart';
import '../../../accessibility/data/accessibility_channel.dart';
import '../../../file_transfer/presentation/providers/file_transfer_provider.dart';
import '../../../file_transfer/presentation/widgets/transfer_progress_card.dart';
import '../../../file_transfer/data/transfer_history_service.dart';
import '../../../file_transfer/data/models/transfer_log.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class PremiumDashboardPage extends ConsumerStatefulWidget {
  const PremiumDashboardPage({super.key});

  @override
  ConsumerState<PremiumDashboardPage> createState() => _PremiumDashboardPageState();
}

class _PremiumDashboardPageState extends ConsumerState<PremiumDashboardPage> with WidgetsBindingObserver {
  String _clipboardContent = 'Tap "Copy to Phone" to sync...';
  bool _autoSync = false;
  Timer? _clipboardPoller;
  
  // Phase 8: Device stats and remote commands
  final DeviceMonitorService _deviceMonitor = DeviceMonitorService();
  final RemoteCommandService _remoteCommand = RemoteCommandService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Check Android clipboard on load
    _checkLocalClipboard();

    // Register handler for clipboard messages
    WidgetsBinding.instance.addPostFrameCallback((_) async {
       // Request Storage Permission for File Server
       if (Platform.isAndroid) {
          if (await Permission.manageExternalStorage.isDenied) {
             await Permission.manageExternalStorage.request();
          }
       }
       
      ref.read(connectionProvider.notifier).registerMessageHandler((message) async {
        if (message.type == MessageType.clipboard) {
          final content = message.payload['content'] as String?;
          if (content != null) {
            setState(() {
              _clipboardContent = content;
            });
            Clipboard.setData(ClipboardData(text: content));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Clipboard synchronized from PC!')),
            );
          }
        } else if (message.type == MessageType.remoteCommand) {
          // Phase 8: Handle remote commands from Windows
          final action = message.payload['action'] as String?;
          if (action != null) {
            _remoteCommand.handleCommand(action);
          }
        } else if (message.type == MessageType.inputEvent) {
          // Phase 8: Handle input injection (iPhone Mirroring)
          final type = message.payload['type'] as String?;
          final x = message.payload['x'] as double?;
          final y = message.payload['y'] as double?;
          
          if (type == 'tap' && x != null && y != null) {
            // Need to Map normalized (0.0-1.0) coordinates to screen resolution
            // Ideally we get screen size from MediaQuery or native, 
            // but native service expects pixel coords.
            final size = MediaQuery.of(context).size;
            final pixelX = x * size.width * MediaQuery.of(context).devicePixelRatio;
            final pixelY = y * size.height * MediaQuery.of(context).devicePixelRatio;
            
            await AccessibilityChannel.performTap(pixelX, pixelY);
          }
        }
      });
      
      // Phase 8: Start device stats monitoring when connected
      final sendMessage = ref.read(connectionProvider.notifier).sendMessage;
      _deviceMonitor.startMonitoring(sendMessage);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clipboardPoller?.cancel();
    _deviceMonitor.stop();
    _remoteCommand.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_autoSync) {
         _checkLocalClipboard(autoSend: true);
      } else {
         _checkLocalClipboard();
      }
    } else if (state == AppLifecycleState.paused) {
      // Stop polling to save battery (though Timer is likely paused by OS)
    }
  }
  
  void _toggleAutoSync(bool value) {
    setState(() {
      _autoSync = value;
    });
    
    _clipboardPoller?.cancel();
    if (_autoSync) {
      // Start aggressive polling (foreground only)
      _clipboardPoller = Timer.periodic(const Duration(seconds: 2), (_) {
         _checkLocalClipboard(autoSend: true);
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Auto Sync Enabled (Foreground)')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Auto Sync Disabled')));
    }
  }

  String? _lastSentClipboard;

  Future<void> _checkLocalClipboard({bool autoSend = false}) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
       // Update UI preview
       // setState(() => _clipboardContent = data.text!);
       
       if (autoSend && data.text != _lastSentClipboard) {
         _lastSentClipboard = data.text;
         _sendToPC();
       }
    }
  }
  
  void _sendToPC() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      // Don't send if same as what PC just sent us (loop prevention)
      // Implementation pending loop check, but for now relies on content diff.
      
      ref.read(connectionProvider.notifier).sendMessage(
        MessageEnvelope(
          type: MessageType.clipboard,
          messageId: const Uuid().v4(),
          timestamp: DateTime.now(),
          payload: {'content': data!.text},
        ),
      );
      if (!_autoSync) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sent to PC Clipboard!')));
      }
    }
  }
  
  Future<void> _pickAndSendFile() async {
    final connectionState = ref.read(connectionProvider);
    
    if (!connectionState.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not connected to PC!')));
      return;
    }
    
    final targetIP = connectionState.connectedAddress;
    if (targetIP == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Unknown target IP!')));
      return;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      
      // Use Phase 9 File Transfer Engine
      ref.read(fileTransferProvider.notifier).sendFile(file, targetIP);
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Starting high-speed transfer...')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final transferState = ref.watch(fileTransferProvider);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text(
                'DASHBOARD',
                style: GoogleFonts.orbitron(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              // Auto Sync Switch
              Row(
                children: [
                  Text('Auto Sync', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                  Switch(
                    value: _autoSync,
                    onChanged: _toggleAutoSync,
                    activeColor: VelocityTheme.electricCyan,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Connection Status Indicator
          Consumer(
            builder: (context, ref, _) {
              final connectionState = ref.watch(connectionProvider);
              final isConnected = connectionState.isConnected;
              final deviceName = connectionState.remoteDevice?.deviceName ?? 'Unknown';
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isConnected 
                      ? Colors.green.withOpacity(0.15) 
                      : Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isConnected ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isConnected ? Icons.link : Icons.link_off,
                      size: 16,
                      color: isConnected ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isConnected ? 'Connected to $deviceName' : 'Not Connected',
                      style: GoogleFonts.inter(
                        color: isConnected ? Colors.green : Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          
          // Phase 9: Active Transfer Card
          if (transferState.isTransferring && transferState.metrics != null) ...[
             TransferProgressCard(
                fileName: transferState.currentFileName ?? 'File',
                metrics: transferState.metrics!,
                onCancel: () {
                   ref.read(fileTransferProvider.notifier).cancel();
                },
             ),
             const SizedBox(height: 24),
          ],

          // 1. Universal Clipboard Card
          _buildClipboardCard(),

          const SizedBox(height: 24),

          // 2. Quick Drop Button
          _buildQuickDropButton(),

          const SizedBox(height: 32),

          // 3. Recent Transfers Header
          Text(
            'RECENT TRANSFERS',
            style: GoogleFonts.orbitron(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),

          // Recent Transfers List - Using Real Data
          ValueListenableBuilder<Box<TransferLog>>(
            valueListenable: TransferHistoryService.transferBox.listenable(),
            builder: (context, box, _) {
              final logs = TransferHistoryService.getAllLogs().take(5).toList();
              if (logs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      'No transfers yet\nSend or receive files to see them here',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
                    ),
                  ),
                );
              }
              return Column(
                children: logs.map((log) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildTransferItem(
                    log.fileName,
                    TransferLog.formatFileSize(log.fileSize),
                    log.status == TransferStatus.completed,
                  ),
                )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildClipboardCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            VelocityTheme.neonPurple.withOpacity(0.2),
            VelocityTheme.neonPurple.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: VelocityTheme.neonPurple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.content_paste, color: VelocityTheme.neonPurple),
              const SizedBox(width: 12),
              Text(
                'Universal Clipboard',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _clipboardContent,
              style: GoogleFonts.robotoMono(color: Colors.white70),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Sync Logic (Download)
                    ref.read(connectionProvider.notifier).sendMessage(
                      MessageEnvelope(
                        type: MessageType.clipboard,
                        messageId: const Uuid().v4(),
                        timestamp: DateTime.now(),
                        payload: {'content': 'Sync Request'},
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Requesting sync...')));
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('GET FROM PC'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _sendToPC,
                  icon: const Icon(Icons.upload),
                  label: const Text('SEND'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VelocityTheme.neonPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickDropButton() {
    return GestureDetector(
      onTap: _pickAndSendFile,
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: VelocityTheme.electricCyan.withOpacity(0.1),
          border: Border.all(color: VelocityTheme.electricCyan.withOpacity(0.3), width: 1), 
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_upload_outlined, size: 40, color: VelocityTheme.electricCyan),
            const SizedBox(height: 8),
            Text(
              'Quick Drop',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              'Tap to select files',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferItem(String name, String size, bool completed) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.insert_drive_file, color: Colors.white70),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: Colors.white), overflow: TextOverflow.ellipsis),
                Text(size, style: GoogleFonts.inter(fontSize: 12, color: Colors.white38)),
              ],
            ),
          ),
          if (completed)
            const Icon(Icons.check_circle, color: Colors.green, size: 20)
          else
            const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white30),
            ),
        ],
      ),
    );
  }
}

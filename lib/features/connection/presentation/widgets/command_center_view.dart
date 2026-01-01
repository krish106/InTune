import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:animate_do/animate_do.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:animate_do/animate_do.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/velocity_theme.dart';
import '../../../../core/models/connection_state.dart' as conn;
import '../../../../core/models/message_envelope.dart';
import '../providers/connection_provider.dart';
import '../../../file_transfer/presentation/widgets/transfer_progress_card.dart';

class CommandCenterView extends ConsumerStatefulWidget {
  final conn.ConnectionState connectionState;
  
  const CommandCenterView({
    super.key,
    required this.connectionState,
  });

  @override
  ConsumerState<CommandCenterView> createState() => _CommandCenterViewState();
}

class _CommandCenterViewState extends ConsumerState<CommandCenterView> {
  bool _isDragging = false;
  
  // Device stats (updated via WebSocket)
  int _batteryLevel = 0;
  bool _isCharging = false;
  String _signal = 'Waiting...';
  String _storage = 'Waiting...';

  @override
  void initState() {
    super.initState();
    
    // Register handler for device stats messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(connectionProvider.notifier).registerMessageHandler((message) async {
        if (message.type == MessageType.deviceStats) {
          _updateDeviceStats(message.payload);
        }
      });
    });
  }

  void _updateDeviceStats(Map<String, dynamic> payload) {
    if (mounted) {
      setState(() {
        _batteryLevel = payload['battery'] ?? 0;
        _isCharging = payload['batteryCharging'] ?? false;
        _signal = payload['signal'] ?? 'Unknown';
        _storage = payload['storage'] ?? 'Unknown';
      });
    }
  }

  Future<void> _sendFile(String filePath) async {
    final file = File(filePath);
    final fileName = file.uri.pathSegments.last;
    final fileSize = await file.length();
    
    print('📂 Sending file: $fileName ($fileSize bytes)');
    
    // Send header
    final transferId = const Uuid().v4();
    ref.read(connectionProvider.notifier).sendMessage(
      MessageEnvelope(
        type: MessageType.fileTransfer,
        messageId: const Uuid().v4(),
        timestamp: DateTime.now(),
        payload: {
          'action': 'header',
          'transferId': transferId,
          'fileName': fileName,
          'fileSize': fileSize,
          'fileType': fileName.split('.').last,
        },
      ),
    );

    // Stream chunks
    const chunkSize = 40 * 1024;
    final stream = file.openRead();
    int chunkIndex = 0;

    try {
      await for (List<int> chunk in stream) {
        String chunkData = base64Encode(chunk);
        
        ref.read(connectionProvider.notifier).sendMessage(
          MessageEnvelope(
            type: MessageType.fileTransfer,
            messageId: const Uuid().v4(),
            timestamp: DateTime.now(),
            payload: {
              'action': 'chunk',
              'transferId': transferId,
              'chunkIndex': chunkIndex,
              'data': chunkData,
            },
          ),
        );
        
        chunkIndex++;
        await Future.delayed(const Duration(milliseconds: 5));
      }
      
      // Send end
      ref.read(connectionProvider.notifier).sendMessage(
        MessageEnvelope(
          type: MessageType.fileTransfer,
          messageId: const Uuid().v4(),
          timestamp: DateTime.now(),
          payload: {
            'action': 'end',
            'transferId': transferId,
            'status': 'success',
          },
        ),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ File sent: $fileName')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Transfer failed: $e')),
      );
    }
  }

  void _sendRingCommand() {
    ref.read(connectionProvider.notifier).sendMessage(
      MessageEnvelope(
        type: MessageType.remoteCommand,
        messageId: const Uuid().v4(),
        timestamp: DateTime.now(),
        payload: {'action': 'RING'},
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('📱 Ring command sent!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            FadeInDown(
              duration: const Duration(milliseconds: 400),
              child: _buildHeader(),
            ),
            
            if (widget.connectionState.currentUploadFile != null && widget.connectionState.uploadMetrics != null) ...[
              const SizedBox(height: 24),
              FadeInDown(
                child: TransferProgressCard(
                  fileName: widget.connectionState.currentUploadFile!,
                  metrics: widget.connectionState.uploadMetrics!,
                  onCancel: () {
                    // Cannot cancel server-side receive easily without killing socket
                  },
                ),
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Drag & Drop Zone
            FadeInUp(
              duration: const Duration(milliseconds: 500),
              delay: const Duration(milliseconds: 100),
              child: _buildDropZone(context),
            ),
            
            const SizedBox(height: 32),
            
            // 3-Card Grid
            SizedBox(
              height: 280, // Fixed height for grid
              child: FadeInUp(
                duration: const Duration(milliseconds: 500),
                delay: const Duration(milliseconds: 200),
                child: _build3CardGrid(),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.6),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Connected to: ${widget.connectionState.remoteDevice?.deviceName ?? "Unknown"}',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
  
  Widget _buildDropZone(BuildContext context) {
    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: (details) async {
        setState(() => _isDragging = false);
        if (details.files.isNotEmpty) {
          final filePath = details.files.first.path;
          final fileName = details.files.first.name;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('📤 Sending $fileName...')),
          );
          await _sendFile(filePath);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: DottedBorder(
          dashPattern: const [12, 6],
          borderType: BorderType.RRect,
          radius: const Radius.circular(20),
          color: _isDragging ? Colors.white : VelocityTheme.electricCyan,
          strokeWidth: _isDragging ? 3 : 2,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isDragging
                    ? [
                        VelocityTheme.electricCyan.withOpacity(0.2),
                        VelocityTheme.neonPurple.withOpacity(0.2),
                      ]
                    : [
                        VelocityTheme.electricCyan.withOpacity(0.05),
                        VelocityTheme.neonPurple.withOpacity(0.05),
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isDragging ? '📥' : '☁️',
                    style: TextStyle(
                      fontSize: _isDragging ? 80 : 64,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isDragging 
                        ? 'Release to send!'
                        : 'Drag & Drop files here to send instantly',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: _isDragging ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (!_isDragging) ...[
                    const SizedBox(height: 8),
                    Text(
                      'or click to browse',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _build3CardGrid() {
    return Row(
      children: [
        Expanded(child: _buildClipboardCard()),
        const SizedBox(width: 16),
        Expanded(child: _buildDeviceStatsCard()),
      ],
    );
  }
  
  Widget _buildClipboardCard() {
    return _buildCard(
      title: 'Clipboard',
      emoji: '📋',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: VelocityTheme.deepNavy,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Tap "Sync" to get Android clipboard',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white70,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // Sync clipboard
                ref.read(connectionProvider.notifier).sendMessage(
                  MessageEnvelope(
                    type: MessageType.clipboard,
                    messageId: const Uuid().v4(),
                    timestamp: DateTime.now(),
                    payload: {'content': 'GET'},
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Requesting clipboard sync...')),
                );
              },
              icon: const Text('🔄', style: TextStyle(fontSize: 16)),
              label: const Text('Sync Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: VelocityTheme.electricCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDeviceStatsCard() {
    return _buildCard(
      title: 'Device Stats',
      emoji: '📱',
      child: Column(
        children: [
          _buildStatRow(
            'Battery', 
            '$_batteryLevel%${_isCharging ? " ⚡" : ""}', 
            _batteryLevel > 50 ? Colors.green : Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildStatRow('Signal', _signal, VelocityTheme.electricCyan),
          const SizedBox(height: 12),
          _buildStatRow('Storage', _storage, Colors.orange),
        ],
      ),
    );
  }
  
  Widget _buildQuickActionsCard() {
    return _buildCard(
      title: 'Quick Actions',
      emoji: '⚡',
      child: Column(
        children: [
          // Removed Screen Share button
          _buildActionButton('🔓 Unlock PC', VelocityTheme.neonPurple, () {
            // TODO: Implement unlock
          }),
          const SizedBox(height: 8),
          _buildActionButton('🔔 Ring Device', Colors.orange, _sendRingCommand),
        ],
      ),
    );
  }
  
  Widget _buildCard({
    required String title,
    required String emoji,
    required Widget child,
  }) {
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
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: child),
        ],
      ),
    );
  }
  
  Widget _buildStatRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildActionButton(String label, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.5)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

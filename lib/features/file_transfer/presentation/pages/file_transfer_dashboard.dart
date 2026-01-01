import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_file/open_file.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:ui';
import 'dart:io';
import '../../../../core/theme/velocity_theme.dart';
import '../../data/models/transfer_log.dart';
import '../../data/transfer_history_service.dart';

/// Transfer Command Center - File Transfer Dashboard
class FileTransferDashboard extends StatefulWidget {
  const FileTransferDashboard({super.key});

  @override
  State<FileTransferDashboard> createState() => _FileTransferDashboardState();
}

class _FileTransferDashboardState extends State<FileTransferDashboard> {
  FileCategory? _selectedFilter;
  String _currentPath = 'Loading...';
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final path = await TransferHistoryService.getDownloadPath();
    if (mounted) {
      setState(() {
        _currentPath = path;
        _initialized = true;
      });
    }
  }

  Future<void> _changeStoragePath() async {
    final newPath = await TransferHistoryService.pickDownloadDirectory();
    if (newPath != null && mounted) {
      setState(() {
        _currentPath = newPath;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Storage path updated: $newPath')),
      );
    }
  }

  Future<void> _openFolder(String path) async {
    try {
      if (Platform.isWindows) {
        await Process.run('explorer.exe', [path]);
      } else if (Platform.isAndroid) {
        // Open file manager to path
        final uri = Uri.parse('content://$path');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      }
    } catch (e) {
      print('❌ Error opening folder: $e');
    }
  }

  Future<void> _openFile(String filePath) async {
    try {
      final result = await OpenFile.open(filePath);
      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot open file: ${result.message}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening file: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Center(
        child: CircularProgressIndicator(color: VelocityTheme.electricCyan),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'TRANSFER CENTER',
            style: GoogleFonts.orbitron(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 24),

          // Section A: Stats Header
          _buildStatsHeader(),
          const SizedBox(height: 24),

          // Section B: Filters
          _buildFilters(),
          const SizedBox(height: 24),

          // Section C: History List
          _buildHistorySection(),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use wrap layout for narrow screens (mobile)
        if (constraints.maxWidth < 500) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildStatCard(
                    icon: Icons.download_rounded,
                    label: 'Received',
                    value: TransferLog.formatFileSize(TransferHistoryService.getTotalReceivedBytes()),
                    color: VelocityTheme.electricCyan,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard(
                    icon: Icons.swap_horiz_rounded,
                    label: 'Files Shared',
                    value: '${TransferHistoryService.getFileCount()} items',
                    color: VelocityTheme.neonPurple,
                  )),
                ],
              ),
              const SizedBox(height: 12),
              _buildStoragePathCard(),
            ],
          );
        }
        
        // Wide screen layout (desktop)
        return Row(
          children: [
            Expanded(child: _buildStatCard(
              icon: Icons.download_rounded,
              label: 'Received',
              value: TransferLog.formatFileSize(TransferHistoryService.getTotalReceivedBytes()),
              color: VelocityTheme.electricCyan,
            )),
            const SizedBox(width: 12),
            
            Expanded(child: _buildStatCard(
              icon: Icons.swap_horiz_rounded,
              label: 'Files Shared',
              value: '${TransferHistoryService.getFileCount()} items',
              color: VelocityTheme.neonPurple,
            )),
            const SizedBox(width: 12),
            
            Expanded(child: _buildStoragePathCard()),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.2),
                color.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  icon == Icons.download_rounded ? '📥' : '🔄',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: GoogleFonts.orbitron(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoragePathCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green.withOpacity(0.2),
                Colors.green.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('📁', style: TextStyle(fontSize: 20)),
                  ),
                  const Spacer(),
                  // Open folder button
                  GestureDetector(
                    onTap: () => _openFolder(_currentPath),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('📂 Open', style: TextStyle(fontSize: 10, color: Colors.white70)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _getShortPath(_currentPath),
                style: GoogleFonts.robotoMono(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Save Location',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 12),
              // CHANGE BUTTON - prominent
              GestureDetector(
                onTap: _changeStoragePath,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.5)),
                  ),
                  child: Center(
                    child: Text(
                      '✏️ CHANGE',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getShortPath(String path) {
    if (path.length <= 20) return path;
    final parts = path.split(Platform.pathSeparator);
    if (parts.length <= 2) return path;
    return '...${Platform.pathSeparator}${parts.last}';
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(null, 'All', Icons.list_alt),
          const SizedBox(width: 8),
          _buildFilterChip(FileCategory.image, 'Images', Icons.image),
          const SizedBox(width: 8),
          _buildFilterChip(FileCategory.video, 'Videos', Icons.videocam),
          const SizedBox(width: 8),
          _buildFilterChip(FileCategory.document, 'Docs', Icons.description),
          const SizedBox(width: 8),
          _buildFilterChip(FileCategory.archive, 'APKs', Icons.inventory_2),
          const SizedBox(width: 8),
          _buildFilterChip(FileCategory.audio, 'Audio', Icons.audiotrack),
        ],
      ),
    );
  }

  Widget _buildFilterChip(FileCategory? category, String label, IconData icon) {
    final isSelected = _selectedFilter == category;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? VelocityTheme.electricCyan.withOpacity(0.3) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? VelocityTheme.electricCyan : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? VelocityTheme.electricCyan : Colors.white54),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.white : Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TRANSFER HISTORY',
          style: GoogleFonts.orbitron(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        
        // ValueListenableBuilder for auto-update
        ValueListenableBuilder<Box<TransferLog>>(
          valueListenable: TransferHistoryService.transferBox.listenable(),
          builder: (context, box, _) {
            List<TransferLog> logs = _selectedFilter == null
                ? TransferHistoryService.getAllLogs()
                : TransferHistoryService.getLogsByCategory(_selectedFilter!);

            if (logs.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _buildTransferTile(logs[index]),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '☁️',
            style: TextStyle(
              fontSize: 60,
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Transfers Yet',
            style: GoogleFonts.orbitron(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white38,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send or receive files to see them here',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferTile(TransferLog log) {
    final isReceived = log.direction == TransferDirection.received;
    final categoryIcon = _getCategoryIcon(log.fileType);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          // Leading: File Type Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getCategoryColor(log.fileType).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                categoryIcon,
                color: _getCategoryColor(log.fileType),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _truncateMiddle(log.fileName, 25),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      TransferLog.formatFileSize(log.fileSize),
                      style: GoogleFonts.robotoMono(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                    const Text(' • ', style: TextStyle(color: Colors.white24)),
                    Icon(
                      isReceived ? Icons.download : Icons.upload,
                      size: 12,
                      color: isReceived ? Colors.green : Colors.blue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      TransferLog.formatRelativeTime(log.timestamp),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Open File
              IconButton(
                onPressed: () => _openFile(log.filePath),
                icon: const Icon(Icons.visibility, size: 20),
                color: Colors.white54,
                tooltip: 'Open File',
              ),
              // Open Folder
              IconButton(
                onPressed: () => _openFolder(File(log.filePath).parent.path),
                icon: const Icon(Icons.folder_open, size: 20),
                color: Colors.white54,
                tooltip: 'Open Folder',
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(FileCategory category) {
    switch (category) {
      case FileCategory.image:
        return Icons.image;
      case FileCategory.video:
        return Icons.videocam;
      case FileCategory.audio:
        return Icons.audiotrack;
      case FileCategory.document:
        return Icons.description;
      case FileCategory.archive:
        return Icons.inventory_2;
      case FileCategory.other:
        return Icons.insert_drive_file;
    }
  }

  Color _getCategoryColor(FileCategory category) {
    switch (category) {
      case FileCategory.image:
        return Colors.pink;
      case FileCategory.video:
        return Colors.red;
      case FileCategory.audio:
        return Colors.orange;
      case FileCategory.document:
        return Colors.blue;
      case FileCategory.archive:
        return Colors.green;
      case FileCategory.other:
        return Colors.grey;
    }
  }

  String _truncateMiddle(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    final half = (maxLength - 3) ~/ 2;
    return '${text.substring(0, half)}...${text.substring(text.length - half)}';
  }
}

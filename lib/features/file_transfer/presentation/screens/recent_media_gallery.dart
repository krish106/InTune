import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/file_transfer_provider.dart';

class RecentMediaGallery extends ConsumerStatefulWidget {
  const RecentMediaGallery({super.key});

  @override
  ConsumerState<RecentMediaGallery> createState() => _RecentMediaGalleryState();
}

class _RecentMediaGalleryState extends ConsumerState<RecentMediaGallery> {
  @override
  void initState() {
    super.initState();
    // Load recent media on init
    Future.microtask(() {
      ref.read(fileTransferProvider.notifier).loadRecentFiles();
    });
  }

  @override
  Widget build(BuildContext context) {
    final fileState = ref.watch(fileTransferProvider);
    final recentFiles = fileState.recentFiles;

    if (recentFiles.isEmpty) {
      return const Center(
        child: Text(
          'No recent media found',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0E1B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D1E33),
        title: const Text('Recent Photos & Videos'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: recentFiles.length,
        itemBuilder: (context, index) {
          final file = recentFiles[index];
          final isVideo = file.name.toLowerCase().endsWith('.mp4');

          return GestureDetector(
            onTap: () => _showFileActions(context, file),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Thumbnail
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: isVideo
                      ? const Icon(Icons.play_circle_outline, color: Colors.white, size: 48)
                      : Image.file(
                          File(file.path),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.broken_image, color: Colors.white54);
                          },
                        ),
                ),
                // Video indicator
                if (isVideo)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.videocam, size: 16, color: Colors.white),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showFileActions(BuildContext context, FileInfo file) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1D1E33),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              file.name,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              '${file.formattedSize} • ${_formatDate(file.modified)}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.send, color: Color(0xFF00D9FF)),
              title: const Text('Send to Computer', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                ref.read(fileTransferProvider.notifier).sendFile(file.path);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('📤 Sending ${file.name}...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.download, color: Colors.green),
              title: const Text('Download', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Already on device')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

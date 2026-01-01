import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/remote_file_system_provider.dart';
import '../../../../core/theme/velocity_theme.dart';
import 'package:path/path.dart' as p;
import 'package:transparent_image/transparent_image.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class RemoteExplorerView extends ConsumerStatefulWidget {
  const RemoteExplorerView({super.key});

  @override
  ConsumerState<RemoteExplorerView> createState() => _RemoteExplorerViewState();
}

class _RemoteExplorerViewState extends ConsumerState<RemoteExplorerView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load initial root
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(remoteFileSystemProvider.notifier).listDirectory('/storage/emulated/0');
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(remoteFileSystemProvider);
    final notifier = ref.read(remoteFileSystemProvider.notifier);

    return Column(
      children: [
        _buildBreadcrumb(state.currentPath, notifier),
        if (state.isLoading)
          const LinearProgressIndicator(color: VelocityTheme.electricCyan, backgroundColor: Colors.transparent),
          
        Expanded(
          child: state.error != null
             ? Center(child: Text('Error: ${state.error}', style: const TextStyle(color: Colors.red)))
             : _buildGrid(state.items, notifier, state.currentPath),
        ),
      ],
    );
  }

  Widget _buildBreadcrumb(String path, RemoteFileSystemNotifier notifier) {
    final parts = path.split('/').where((e) => e.isNotEmpty).toList();
    
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.black.withOpacity(0.3),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_upward, color: Colors.white70),
            onPressed: () => notifier.navigateUp(),
            tooltip: 'Up',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: parts.length,
              separatorBuilder: (_, __) => const Icon(Icons.chevron_right, color: Colors.white30, size: 16),
              itemBuilder: (context, index) {
                final part = parts[index];
                return TextButton(
                  onPressed: () {
                     // Reconstruct path to this part
                     // Ensure leading /
                     final target = '/' + parts.sublist(0, index + 1).join('/');
                     notifier.listDirectory(target);
                  },
                  child: Text(part, style: GoogleFonts.inter(color: Colors.white)),
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () => notifier.listDirectory(path),
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.create_new_folder, color: Colors.white70),
            onPressed: () => _showCreateDirDialog(context, notifier, path),
            tooltip: 'New Folder',
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<RemoteFileItem> items, RemoteFileSystemNotifier notifier, String currentPath) {
    if (items.isEmpty) {
      return Center(child: Text('Empty Folder', style: GoogleFonts.inter(color: Colors.white54)));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = (width / 120).floor().clamp(2, 10); 

        return GridView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.8,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _buildItemCard(item, notifier);
          },
        );
      }
    );
  }

  Widget _buildItemCard(RemoteFileItem item, RemoteFileSystemNotifier notifier) {
    return GestureDetector(
      onDoubleTap: () {
        if (item.isDir) {
          notifier.listDirectory(item.path);
        } else {
          _downloadFile(item, notifier);
        }
      },
      onSecondaryTapUp: (details) {
        _showContextMenu(context, details.globalPosition, item, notifier);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
             Expanded(
               child: item.isImage || item.isVideo
                 ? _buildThumbnail(item, notifier)
                 : Center(
                     child: Icon(
                       item.isDir ? Icons.folder : Icons.insert_drive_file,
                       size: 48,
                       color: item.isDir ? VelocityTheme.electricCyan : Colors.white54,
                     ),
                   ),
             ),
             Container(
               padding: const EdgeInsets.all(8),
               color: Colors.black45,
               child: Column(
                 mainAxisSize: MainAxisSize.min,
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(
                     item.name,
                     style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
                     maxLines: 1,
                     overflow: TextOverflow.ellipsis,
                   ),
                   if (!item.isDir)
                     Text(
                       _formatSize(item.size),
                       style: GoogleFonts.inter(fontSize: 10, color: Colors.white54),
                     ),
                 ],
               ),
             ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildThumbnail(RemoteFileItem item, RemoteFileSystemNotifier notifier) {
    // Only show thumbnail if image or video
    // Use FadeInImage for lazy loading
    final url = notifier.getThumbnailUrl(item.path);
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: FadeInImage.memoryNetwork(
        placeholder: kTransparentImage,
        image: url,
        fit: BoxFit.cover,
        imageErrorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.white24)),
      ),
    );
  }
  
  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  
  Future<void> _downloadFile(RemoteFileItem item, RemoteFileSystemNotifier notifier) async {
    Directory? downloadDir;
    if (Platform.isWindows) {
      downloadDir = await getDownloadsDirectory();
    } else {
      downloadDir = await getApplicationDocumentsDirectory();
    }
    
    if (downloadDir != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Downloading ${item.name}...')));
      
      await notifier.downloadFile(item, downloadDir.path);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Download Complete!')));
    }
  }

  void _showContextMenu(BuildContext context, Offset position, RemoteFileItem item, RemoteFileSystemNotifier notifier) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      color: VelocityTheme.cardBackground,
      items: [
        if (!item.isDir)
          PopupMenuItem(
            value: 'download',
            child: Row(children: [Icon(Icons.download, color: Colors.white), SizedBox(width: 8), Text('Download', style: TextStyle(color: Colors.white))]),
          ),
        PopupMenuItem(
          value: 'rename',
          child: Row(children: [Icon(Icons.edit, color: Colors.white), SizedBox(width: 8), Text('Rename', style: TextStyle(color: Colors.white))]),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))]),
        ),
      ],
    ).then((value) {
      if (value == 'download') {
        _downloadFile(item, notifier);
      } else if (value == 'rename') {
        _showRenameDialog(context, notifier, item);
      } else if (value == 'delete') {
        _confirmDelete(context, notifier, item);
      }
    });
  }

  void _showRenameDialog(BuildContext context, RemoteFileSystemNotifier notifier, RemoteFileItem item) {
    final controller = TextEditingController(text: item.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VelocityTheme.deepNavy,
        title: Text('Rename', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
             enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: VelocityTheme.electricCyan)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty && controller.text != item.name) {
                notifier.renameItem(item.path, controller.text);
              }
              Navigator.pop(context);
            }, 
            child: Text('Rename', style: TextStyle(color: VelocityTheme.electricCyan))
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, RemoteFileSystemNotifier notifier, RemoteFileItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VelocityTheme.deepNavy,
        title: Text('Delete ${item.name}?', style: TextStyle(color: Colors.white)),
        content: Text('This cannot be undone.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () {
              notifier.deleteItem(item.path);
              Navigator.pop(context);
            }, 
            child: Text('Delete', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  void _showCreateDirDialog(BuildContext context, RemoteFileSystemNotifier notifier, String currentPath) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VelocityTheme.deepNavy,
        title: Text('New Folder', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
             hintText: 'Folder Name',
             hintStyle: TextStyle(color: Colors.white30),
             enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: VelocityTheme.electricCyan)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                notifier.createDirectory(currentPath, controller.text);
              }
              Navigator.pop(context);
            }, 
            child: Text('Create', style: TextStyle(color: VelocityTheme.electricCyan))
          ),
        ],
      ),
    );
  }
}

import 'package:hive/hive.dart';

part 'transfer_log.g.dart';

/// File type enum for categorizing transfers
@HiveType(typeId: 1)
enum FileCategory {
  @HiveField(0)
  image,
  @HiveField(1)
  video,
  @HiveField(2)
  document,
  @HiveField(3)
  archive,
  @HiveField(4)
  audio,
  @HiveField(5)
  other,
}

/// Transfer direction enum
@HiveType(typeId: 2)
enum TransferDirection {
  @HiveField(0)
  sent,
  @HiveField(1)
  received,
}

/// Transfer status enum
@HiveType(typeId: 3)
enum TransferStatus {
  @HiveField(0)
  completed,
  @HiveField(1)
  failed,
  @HiveField(2)
  inProgress,
}

/// TransferLog model for persistent file transfer history
@HiveType(typeId: 0)
class TransferLog extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String fileName;

  @HiveField(2)
  final String filePath;

  @HiveField(3)
  final int fileSize;

  @HiveField(4)
  final FileCategory fileType;

  @HiveField(5)
  final DateTime timestamp;

  @HiveField(6)
  final TransferDirection direction;

  @HiveField(7)
  final TransferStatus status;

  TransferLog({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.fileType,
    required this.timestamp,
    required this.direction,
    required this.status,
  });

  /// Get file category from extension
  static FileCategory getCategoryFromExtension(String extension) {
    final ext = extension.toLowerCase();
    
    const imageExts = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'svg', 'ico'];
    const videoExts = ['mp4', 'mkv', 'avi', 'mov', 'wmv', 'flv', 'webm', '3gp'];
    const audioExts = ['mp3', 'wav', 'flac', 'aac', 'ogg', 'm4a', 'wma'];
    const docExts = ['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx', 'ppt', 'pptx', 'odt', 'rtf'];
    const archiveExts = ['zip', 'rar', '7z', 'tar', 'gz', 'apk', 'xapk'];

    if (imageExts.contains(ext)) return FileCategory.image;
    if (videoExts.contains(ext)) return FileCategory.video;
    if (audioExts.contains(ext)) return FileCategory.audio;
    if (docExts.contains(ext)) return FileCategory.document;
    if (archiveExts.contains(ext)) return FileCategory.archive;
    
    return FileCategory.other;
  }

  /// Get icon for file category
  static String getIconForCategory(FileCategory category) {
    switch (category) {
      case FileCategory.image:
        return '🖼️';
      case FileCategory.video:
        return '🎥';
      case FileCategory.audio:
        return '🎵';
      case FileCategory.document:
        return '📄';
      case FileCategory.archive:
        return '📦';
      case FileCategory.other:
        return '📁';
    }
  }

  /// Format file size to human readable
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Format relative time
  static String formatRelativeTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }
}

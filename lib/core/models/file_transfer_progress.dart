enum TransferStatus { pending, transferring, completed, failed, cancelled }

enum TransferDirection { sending, receiving }

class FileTransferProgress {
  final String transferId;
  final String fileName;
  final int totalBytes;
  final int transferredBytes;
  final TransferStatus status;
  final TransferDirection direction;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? errorMessage;
  final String? savePath;
  
  FileTransferProgress({
    required this.transferId,
    required this.fileName,
    required this.totalBytes,
    required this.transferredBytes,
    required this.status,
    required this.direction,
    required this.startedAt,
    this.completedAt,
    this.errorMessage,
    this.savePath,
  });
  
  double get progressPercentage {
    if (totalBytes == 0) return 0.0;
    return (transferredBytes / totalBytes) * 100;
  }
  
  String get formattedProgress {
    return '${_formatBytes(transferredBytes)} / ${_formatBytes(totalBytes)}';
  }
  
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  
  Duration? get transferDuration {
    if (completedAt == null) return null;
    return completedAt!.difference(startedAt);
  }
  
  String? get transferSpeed {
    final duration = transferDuration;
    if (duration == null || duration.inSeconds == 0) return null;
    
    final bytesPerSecond = transferredBytes / duration.inSeconds;
    return '${_formatBytes(bytesPerSecond.toInt())}/s';
  }
  
  FileTransferProgress copyWith({
    int? transferredBytes,
    TransferStatus? status,
    DateTime? completedAt,
    String? errorMessage,
    String? savePath,
  }) {
    return FileTransferProgress(
      transferId: transferId,
      fileName: fileName,
      totalBytes: totalBytes,
      transferredBytes: transferredBytes ?? this.transferredBytes,
      status: status ?? this.status,
      direction: direction,
      startedAt: startedAt,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      savePath: savePath ?? this.savePath,
    );
  }
  
  @override
  String toString() {
    return 'FileTransferProgress(fileName: $fileName, progress: ${progressPercentage.toStringAsFixed(1)}%, status: $status)';
  }
}

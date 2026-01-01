class FileTransferConstants {
  // HTTP Endpoints
  static const String uploadEndpoint = '/upload';
  static const String downloadEndpoint = '/download';
  
  // Chunk Size for Streaming (8MB chunks)
  static const int chunkSize = 8 * 1024 * 1024;
  
  // Timeouts
  static const Duration uploadTimeout = Duration(hours: 2);
  static const Duration downloadTimeout = Duration(hours: 2);
  
  // File Limits
  static const int maxFileSizeBytes = 10 * 1024 * 1024 * 1024; // 10GB
  
  // Downloads Directory
  static const String downloadsSubfolder = 'VelocityLink';
}

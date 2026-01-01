class FileTransferRequest {
  final String transferId;
  final String fileName;
  final int fileSize;
  final String mimeType;
  final String senderDeviceId;
  
  FileTransferRequest({
    required this.transferId,
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
    required this.senderDeviceId,
  });
  
  Map<String, dynamic> toPayload() => {
    'transferId': transferId,
    'fileName': fileName,
    'fileSize': fileSize,
    'mimeType': mimeType,
    'senderDeviceId': senderDeviceId,
  };
  
  static FileTransferRequest fromPayload(Map<String, dynamic> payload) {
    return FileTransferRequest(
      transferId: payload['transferId'] as String,
      fileName: payload['fileName'] as String,
      fileSize: payload['fileSize'] as int,
      mimeType: payload['mimeType'] as String,
      senderDeviceId: payload['senderDeviceId'] as String,
    );
  }
  
  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(2)} KB';
    if (fileSize < 1024 * 1024 * 1024) return '${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB';
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
  
  @override
  String toString() {
    return 'FileTransferRequest(fileName: $fileName, size: $formattedSize)';
  }
}

class FileTransferResponse {
  final String transferId;
  final bool accepted;
  final String? reason;
  
  FileTransferResponse({
    required this.transferId,
    required this.accepted,
    this.reason,
  });
  
  Map<String, dynamic> toPayload() => {
    'transferId': transferId,
    'accepted': accepted,
    'reason': reason,
  };
  
  static FileTransferResponse fromPayload(Map<String, dynamic> payload) {
    return FileTransferResponse(
      transferId: payload['transferId'] as String,
      accepted: payload['accepted'] as bool,
      reason: payload['reason'] as String?,
    );
  }
}

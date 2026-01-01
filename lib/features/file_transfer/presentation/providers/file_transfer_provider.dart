import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/file_transfer_service.dart';
import '../../../../core/utils/speed_calculator.dart';

// State model for transfer
class FileTransferState {
  final bool isTransferring;
  final String? currentFileName;
  final TransferMetrics? metrics;
  final String? error;

  FileTransferState({
    this.isTransferring = false,
    this.currentFileName,
    this.metrics,
    this.error,
  });

  FileTransferState copyWith({
    bool? isTransferring,
    String? currentFileName,
    TransferMetrics? metrics,
    String? error,
  }) {
    return FileTransferState(
      isTransferring: isTransferring ?? this.isTransferring,
      currentFileName: currentFileName ?? this.currentFileName,
      metrics: metrics ?? this.metrics,
      error: error,
    );
  }
}

// Provider
final fileTransferProvider = StateNotifierProvider<FileTransferNotifier, FileTransferState>((ref) {
  return FileTransferNotifier();
});

class FileTransferNotifier extends StateNotifier<FileTransferState> {
  final _service = FileTransferService();

  FileTransferNotifier() : super(FileTransferState());

  Future<void> sendFile(File file, String targetIP) async {
    if (state.isTransferring) return;

    final fileName = file.uri.pathSegments.last;
    state = FileTransferState(
      isTransferring: true,
      currentFileName: fileName,
      metrics: TransferMetrics.empty(),
    );

    await _service.uploadFile(
      file: file,
      targetIP: targetIP,
      onProgress: (metrics) {
        state = state.copyWith(metrics: metrics);
      },
      onComplete: () {
        state = FileTransferState(isTransferring: false);
      },
      onError: (error) {
        state = state.copyWith(
          isTransferring: false,
          error: error,
        );
      },
    );
  }

  void cancel() {
    _service.stopUpload();
    state = FileTransferState(isTransferring: false);
  }
}

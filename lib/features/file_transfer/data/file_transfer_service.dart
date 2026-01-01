import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/speed_calculator.dart';
import '../../../../core/constants/network_constants.dart';

class FileTransferService {
  final Dio _dio = Dio();
  CancelToken? _cancelToken;
  final SpeedCalculator _speedCalculator = SpeedCalculator();
  
  /// Upload file to target IP
  Future<void> stopUpload() async {
    if (_cancelToken != null && !_cancelToken!.isCancelled) {
      _cancelToken!.cancel('User cancelled upload');
    }
  }

  Future<void> uploadFile({
    required File file,
    required String targetIP,
    required Function(TransferMetrics) onProgress,
    required Function(String) onError,
    required Function() onComplete,
  }) async {
    final fileName = file.uri.pathSegments.last;
    final fileSize = await file.length();
    
    _cancelToken = CancelToken();
    _speedCalculator.reset();
    
    final url = 'http://$targetIP:${NetworkConstants.defaultPort}/upload';
    
    try {
      AppLogger.info('📤 Starting upload: $fileName to $url');
      
      // We stream the file directly from disk to avoid memory issues
      // Using Stream.fromIterable is one way, but Dio supports File directly.
      
      await _dio.post(
        url,
        data: file.openRead(), // Stream
        options: Options(
          headers: {
            Headers.contentLengthHeader: fileSize, // Crucial for server
            'x-filename': fileName,
          },
          contentType: 'application/octet-stream', // Raw binary stream
        ),
        cancelToken: _cancelToken,
        onSendProgress: (sent, total) {
          // total might be -1 if chunked, but we set content-length manually
          // so generic http client might not know total unless we pass it.
          // However, we passed fileSize in headers.
          // If total is -1, use fileSize.
          
          final actualTotal = total > 0 ? total : fileSize;
          final metrics = _speedCalculator.addSample(sent, actualTotal);
          onProgress(metrics);
        },
      );
      
      AppLogger.info('✅ Upload complete: $fileName');
      onComplete();
      
    } catch (e) {
      if (CancelToken.isCancel(e as DioException)) {
        AppLogger.info('Upload cancelled');
      } else {
        AppLogger.error('Upload failed', e);
        onError(e.toString());
      }
    } finally {
      _cancelToken = null;
    }
  }
}

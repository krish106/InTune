import 'dart:async';

/// A StreamTransformer that counts bytes as they pass through
/// and calls [onProgress] with the total running count.
class ByteCountingTransformer extends StreamTransformerBase<List<int>, List<int>> {
  final void Function(int bytesProcessed) onProgress;
  int _totalBytes = 0;

  ByteCountingTransformer({required this.onProgress});

  @override
  Stream<List<int>> bind(Stream<List<int>> stream) {
    return stream.transform(
      StreamTransformer<List<int>, List<int>>.fromHandlers(
        handleData: (data, sink) {
          _totalBytes += data.length;
          onProgress(_totalBytes);
          sink.add(data); // Pass data through unchanged
        },
        handleError: (error, stackTrace, sink) {
          sink.addError(error, stackTrace);
        },
        handleDone: (sink) {
          sink.close();
        },
      ),
    );
  }
}

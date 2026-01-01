import 'dart:collection';

class SpeedCalculator {
  static const int _windowSize = 5; // Smoothing window (5 samples)
  final Queue<TransferSample> _samples = Queue();
  
  /// Helper to format bytes per second
  static String formatSpeed(double bytesPerSecond) {
    if (bytesPerSecond < 1024) return '${bytesPerSecond.toStringAsFixed(1)} B/s';
    if (bytesPerSecond < 1024 * 1024) return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }

  /// Helper to format ETR
  static String formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    }
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    }
    return '${duration.inSeconds}s left';
  }

  /// Add a sample and return current metrics
  TransferMetrics addSample(int totalBytesTransferred, int totalFileSize) {
    final now = DateTime.now();
    
    // Add new sample
    _samples.add(TransferSample(timestamp: now, bytes: totalBytesTransferred));
    
    // Maintain window size
    if (_samples.length > _windowSize) {
      _samples.removeFirst();
    }
    
    // Needs at least 2 samples to calculate speed
    if (_samples.length < 2) {
      return TransferMetrics.empty();
    }
    
    // Calculate speed (Moving Average)
    final oldest = _samples.first;
    final newest = _samples.last;
    
    final duration = newest.timestamp.difference(oldest.timestamp).inMilliseconds / 1000.0;
    if (duration == 0) return TransferMetrics.empty();
    
    final bytesDelta = newest.bytes - oldest.bytes;
    final speed = bytesDelta / duration; // Bytes per second
    
    // Calculate ETR
    final remainingBytes = totalFileSize - totalBytesTransferred;
    final etrSeconds = speed > 0 ? (remainingBytes / speed).ceil() : 0;
    
    return TransferMetrics(
      speed: speed,
      speedStr: formatSpeed(speed),
      etr: Duration(seconds: etrSeconds),
      etrStr: formatDuration(Duration(seconds: etrSeconds)),
      percentage: totalFileSize > 0 ? totalBytesTransferred / totalFileSize : 0,
    );
  }
  
  void reset() {
    _samples.clear();
  }
}

class TransferSample {
  final DateTime timestamp;
  final int bytes;
  TransferSample({required this.timestamp, required this.bytes});
}

class TransferMetrics {
  final double speed;
  final String speedStr;
  final Duration etr;
  final String etrStr;
  final double percentage;
  
  TransferMetrics({
    required this.speed, 
    required this.speedStr, 
    required this.etr,
    required this.etrStr,
    required this.percentage,
  });
  
  factory TransferMetrics.empty() => TransferMetrics(
    speed: 0, 
    speedStr: '0 B/s', 
    etr: Duration.zero, 
    etrStr: 'Calculating...', // Better than '-'
    percentage: 0,
  );
}

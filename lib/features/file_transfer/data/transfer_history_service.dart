import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'models/transfer_log.dart';

/// Service for managing transfer history and storage settings
class TransferHistoryService {
  static const String _transferBoxName = 'transfer_logs';
  static const String _settingsBoxName = 'settings';
  static const String _downloadPathKey = 'download_path';

  static Box<TransferLog>? _transferBox;
  static Box<dynamic>? _settingsBox;

  /// Initialize Hive and open boxes
  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TransferLogAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(FileCategoryAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(TransferDirectionAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(TransferStatusAdapter());
    }

    // Open boxes
    _transferBox = await Hive.openBox<TransferLog>(_transferBoxName);
    _settingsBox = await Hive.openBox<dynamic>(_settingsBoxName);
    
    print('📦 TransferHistoryService initialized');
  }

  /// Get the transfer logs box for ValueListenableBuilder
  static Box<TransferLog> get transferBox {
    if (_transferBox == null) {
      throw StateError('TransferHistoryService not initialized. Call init() first.');
    }
    return _transferBox!;
  }
  
  static Box<dynamic>? get settingsBox => _settingsBox;

  /// Add a new transfer log
  static Future<void> addLog({
    required String fileName,
    required String filePath,
    required int fileSize,
    required TransferDirection direction,
    TransferStatus status = TransferStatus.completed,
  }) async {
    final extension = fileName.split('.').last;
    final log = TransferLog(
      id: const Uuid().v4(),
      fileName: fileName,
      filePath: filePath,
      fileSize: fileSize,
      fileType: TransferLog.getCategoryFromExtension(extension),
      timestamp: DateTime.now(),
      direction: direction,
      status: status,
    );

    await _transferBox?.add(log);
    print('📝 Transfer log added: $fileName');
  }

  /// Get all transfer logs (newest first)
  static List<TransferLog> getAllLogs() {
    return _transferBox?.values.toList().reversed.toList() ?? [];
  }

  /// Get logs filtered by category
  static List<TransferLog> getLogsByCategory(FileCategory category) {
    return getAllLogs().where((log) => log.fileType == category).toList();
  }

  /// Get total received size in bytes
  static int getTotalReceivedBytes() {
    return getAllLogs()
        .where((log) => log.direction == TransferDirection.received)
        .fold(0, (sum, log) => sum + log.fileSize);
  }

  /// Get total sent size in bytes
  static int getTotalSentBytes() {
    return getAllLogs()
        .where((log) => log.direction == TransferDirection.sent)
        .fold(0, (sum, log) => sum + log.fileSize);
  }

  /// Get count of files by direction
  static int getFileCount({TransferDirection? direction}) {
    if (direction == null) return getAllLogs().length;
    return getAllLogs().where((log) => log.direction == direction).length;
  }

  /// Clear all transfer logs
  static Future<void> clearAllLogs() async {
    await _transferBox?.clear();
  }

  // ============== STORAGE PATH MANAGEMENT ==============

  /// Get custom download path (or default Downloads folder)
  static Future<String> getDownloadPath() async {
    final customPath = _settingsBox?.get(_downloadPathKey) as String?;
    
    if (customPath != null && await Directory(customPath).exists()) {
      return customPath;
    }

    // Fallback to default Downloads
    if (Platform.isWindows) {
      final dir = await getDownloadsDirectory();
      return dir?.path ?? Directory.current.path;
    } else if (Platform.isAndroid) {
      final dir = await getExternalStorageDirectory();
      return dir?.path ?? '/storage/emulated/0/Download';
    }
    
    return Directory.current.path;
  }

  /// Set custom download path
  static Future<void> setDownloadPath(String path) async {
    await _settingsBox?.put(_downloadPathKey, path);
    print('📁 Download path set to: $path');
  }

  /// Pick a new download directory
  static Future<String?> pickDownloadDirectory() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Download Folder',
      );

      if (selectedDirectory != null) {
        await setDownloadPath(selectedDirectory);
        return selectedDirectory;
      }
    } catch (e) {
      print('❌ Error picking directory: $e');
    }
    return null;
  }

  /// Check if custom path is set
  static bool hasCustomPath() {
    return _settingsBox?.get(_downloadPathKey) != null;
  }

  /// Reset to default download path
  static Future<void> resetToDefaultPath() async {
    await _settingsBox?.delete(_downloadPathKey);
    print('📁 Download path reset to default');
  }

  // ============== ONBOARDING ==============
  static bool get isFirstRun => _settingsBox?.get('isFirstRun', defaultValue: true) ?? true;
  static Future<void> setFirstRunCompleted() async {
    await _settingsBox?.put('isFirstRun', false);
  }
}

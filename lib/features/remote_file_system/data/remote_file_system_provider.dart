import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../connection/presentation/providers/connection_provider.dart';
import 'package:path/path.dart' as p;

final remoteFileSystemProvider = StateNotifierProvider<RemoteFileSystemNotifier, RemoteFileSystemState>((ref) {
  return RemoteFileSystemNotifier(ref);
});

class RemoteFileSystemState {
  final String currentPath;
  final List<RemoteFileItem> items;
  final bool isLoading;
  final String? error;
  
  RemoteFileSystemState({
    required this.currentPath,
    this.items = const [],
    this.isLoading = false,
    this.error,
  });
  
  RemoteFileSystemState copyWith({
    String? currentPath,
    List<RemoteFileItem>? items,
    bool? isLoading,
    String? error,
  }) {
    return RemoteFileSystemState(
      currentPath: currentPath ?? this.currentPath,
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class RemoteFileItem {
  final String name;
  final String path;
  final int size;
  final bool isDir;
  final bool isImage;
  final bool isVideo;
  final String? mimeType;
  
  RemoteFileItem({
    required this.name,
    required this.path,
    required this.size,
    required this.isDir,
    this.isImage = false,
    this.isVideo = false,
    this.mimeType,
  });
  
  factory RemoteFileItem.fromJson(Map<String, dynamic> json) {
    return RemoteFileItem(
      name: json['name'],
      path: json['path'],
      size: json['size'],
      isDir: json['isDir'],
      isImage: json['isImage'] ?? false,
      isVideo: json['isVideo'] ?? false,
      mimeType: json['mimeType'],
    );
  }
}

class RemoteFileSystemNotifier extends StateNotifier<RemoteFileSystemState> {
  final Ref ref;
  final Dio _dio = Dio();
  
  RemoteFileSystemNotifier(this.ref) : super(RemoteFileSystemState(currentPath: '/storage/emulated/0'));
  
  String? get _targetUrl {
    final connectionState = ref.read(connectionProvider);
    if (!connectionState.isConnected) return null;
    
    // Use stored connected address. 
    // If Windows is Host, it stores Client IP in 'connectedAddress' when client connects (I should verify this logic later)
    // Actually, I verified I set 'connectedAddress' in Client flow.
    // For Host flow, I didn't update 'onClientConnected' to save IP.
    // I NEED to fix that for Windows to browse Android.
    
    final ip = connectionState.connectedAddress;
    if (ip == null) return null; // Can't reach device
    
    return 'http://$ip:8081/api';
  }
  
  Future<void> listDirectory(String path) async {
    final baseUrl = _targetUrl;
    if (baseUrl == null) {
      state = state.copyWith(error: 'Not connected to device IP');
      return;
    }
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _dio.get('$baseUrl/list', queryParameters: {'path': path});
      
      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> rawItems = data['items'];
        final items = rawItems.map((e) => RemoteFileItem.fromJson(e)).toList();
        
        state = state.copyWith(
          currentPath: data['path'],
          items: items,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false, error: 'Failed to listing: ${response.statusCode}');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
  
  Future<void> navigateUp() async {
    final parent = p.dirname(state.currentPath);
    if (state.currentPath == '/storage/emulated/0' || state.currentPath == '/') return;
    await listDirectory(parent);
  }
  
  String getThumbnailUrl(String path) {
    final baseUrl = _targetUrl;
    if (baseUrl == null) return '';
    return '$baseUrl/thumbnail?path=${Uri.encodeComponent(path)}';
  }
  
  Future<void> downloadFile(RemoteFileItem item, String saveDir) async {
    final baseUrl = _targetUrl;
    if (baseUrl == null) return;
    
    try {
      final savePath = p.join(saveDir, item.name);
      await _dio.download(
        '$baseUrl/download', 
        savePath,
        queryParameters: {'path': item.path},
      );
    } catch (e) {
      // Handle error
    }
  }

  Future<void> deleteItem(String path) async {
    final baseUrl = _targetUrl;
    if (baseUrl == null) return;
    
    try {
      await _dio.get('$baseUrl/delete', queryParameters: {'path': path});
      await listDirectory(state.currentPath); // Refresh
    } catch (e) {
      state = state.copyWith(error: 'Delete failed: $e');
    }
  }

  Future<void> renameItem(String path, String newName) async {
    final baseUrl = _targetUrl;
    if (baseUrl == null) return;
    
    try {
      await _dio.get('$baseUrl/rename', queryParameters: {'path': path, 'newName': newName});
      await listDirectory(state.currentPath);
    } catch (e) {
      state = state.copyWith(error: 'Rename failed: $e');
    }
  }

  Future<void> createDirectory(String parentPath, String dirName) async {
    final baseUrl = _targetUrl;
    if (baseUrl == null) return;
    
    final target = p.join(parentPath, dirName); // Note: server uses forward slashes?
    // p.join might use backslash on Windows. Better construct manually or normalize.
    // Android expects forward slash.
    final normalizedTarget = '$parentPath/$dirName'.replaceAll(r'\', '/');
    
    try {
      await _dio.get('$baseUrl/create_dir', queryParameters: {'path': normalizedTarget});
      await listDirectory(state.currentPath);
    } catch (e) {
      state = state.copyWith(error: 'Create failed: $e');
    }
  }
}

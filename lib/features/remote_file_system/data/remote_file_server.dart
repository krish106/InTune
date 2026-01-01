import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path/path.dart' as p;
import 'package:mime/mime.dart';
import '../../../../core/utils/logger.dart';

class RemoteFileServer {
  HttpServer? _server;
  static const int _serverPort = 8081; // Secondary port for file API

  bool get isRunning => _server != null;

  Future<void> start() async {
    if (_server != null) return;
    
    // Only run on Android/Mobile for now
    if (Platform.isWindows || Platform.isLinux) return;
    
    try {
      final handler = Pipeline()
          .addMiddleware(logRequests())
          .addHandler(_handleRequest);

      // Listen on all interfaces
      _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, _serverPort);
      AppLogger.info('📂 Remote File Server running on port $_serverPort');
    } catch (e) {
      AppLogger.error('Failed to start Remote File Server', e);
    }
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    AppLogger.info('📂 Remote File Server stopped');
  }

  Future<Response> _handleRequest(Request request) async {
    // CORS headers
    final headers = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Origin, Content-Type, X-Auth-Token',
    };

    if (request.method == 'OPTIONS') {
      return Response.ok('', headers: headers);
    }

    final path = request.url.path;
    final query = request.url.queryParameters;
    final targetPath = query['path'];

    if (!_isSafePath(targetPath) && path != 'api/list') { 
      if (path == 'api/list' && targetPath == null) {
        // Safe to list root if null? No, require logic.
      } else {
        return Response.forbidden('Access Denied', headers: headers);
      }
    }

    try {
      if (path == 'api/list') {
        return _handleList(targetPath ?? '/storage/emulated/0', headers);
      } else if (path == 'api/thumbnail') {
        if (targetPath == null) return Response.badRequest(body: 'Missing path', headers: headers);
        return _handleThumbnail(targetPath, headers);
      } else if (path == 'api/download') {
        if (targetPath == null) return Response.badRequest(body: 'Missing path', headers: headers);
        return _handleDownload(targetPath, headers);
      } else if (path == 'api/delete') {
        if (targetPath == null) return Response.badRequest(body: 'Missing path', headers: headers);
        return _handleDelete(targetPath, headers);
      } else if (path == 'api/rename') {
        final newName = query['newName'];
        if (targetPath == null || newName == null) return Response.badRequest(body: 'Missing path or newName', headers: headers);
        return _handleRename(targetPath, newName, headers);
      } else if (path == 'api/create_dir') {
        if (targetPath == null) return Response.badRequest(body: 'Missing path', headers: headers);
        return _handleCreateDir(targetPath, headers);
      }
    } catch (e) {
      AppLogger.error('API Error: $path', e);
      return Response.internalServerError(body: e.toString(), headers: headers);
    }
    
    return Response.notFound('Not Found', headers: headers);
  }
  
  bool _isSafePath(String? path) {
    if (path == null) return false;
    // Android spec: /storage/emulated/0 is user space
    return path.startsWith('/storage/emulated/0');
  }

  Future<Response> _handleList(String dirPath, Map<String, String> headers) async {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) {
      return Response.notFound('Directory not found', headers: headers);
    }
    
    try {
      final List<FileSystemEntity> entities = dir.listSync();
      
      // Sort: Directories first, then Files. Alphabetical.
      entities.sort((a, b) {
        final aIsDir = a is Directory ? 0 : 1;
        final bIsDir = b is Directory ? 0 : 1;
        if (aIsDir != bIsDir) return aIsDir.compareTo(bIsDir);
        return p.basename(a.path).toLowerCase().compareTo(p.basename(b.path).toLowerCase());
      });
      
      final List<Map<String, dynamic>> items = [];
      
      for (var entity in entities) {
        final name = p.basename(entity.path);
        if (name.startsWith('.')) continue; // Skip hidden
        
        final isDir = entity is Directory;
        int size = 0;
        if (!isDir && entity is File) {
          try { size = entity.lengthSync(); } catch (_) {}
        }
        
        String? mimeType;
        bool isImage = false;
        bool isVideo = false;
        
        if (!isDir) {
          mimeType = lookupMimeType(entity.path);
          if (mimeType != null) {
            if (mimeType.startsWith('image/')) isImage = true;
            if (mimeType.startsWith('video/')) isVideo = true;
          }
        }
        
        items.add({
          'name': name,
          'path': entity.path,
          'size': size,
          'isDir': isDir,
          'isImage': isImage,
          'isVideo': isVideo,
          'mimeType': mimeType,
          'modified': (entity is File) ? entity.lastModifiedSync().toIso8601String() : null,
        });
      }
      
      return Response.ok(
        jsonEncode({'path': dirPath, 'items': items}), 
        headers: {...headers, 'content-type': 'application/json'}
      );
    } catch (e) {
      return Response.internalServerError(body: 'Failed to list directory: $e', headers: headers);
    }
  }

  Future<Response> _handleThumbnail(String filePath, Map<String, String> headers) async {
    final file = File(filePath);
    if (!file.existsSync()) return Response.notFound('File not found', headers: headers);

    final mimeType = lookupMimeType(filePath) ?? '';
    List<int>? thumbBytes;

    try {
      if (mimeType.startsWith('image/')) {
        // Image Compression
        thumbBytes = await FlutterImageCompress.compressWithFile(
          file.absolute.path,
          minWidth: 256,
          minHeight: 256,
          quality: 60,
          format: CompressFormat.jpeg,
        );
      } else if (mimeType.startsWith('video/')) {
        // Video Thumbnail
        // Check platform again just in case
        if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
           final tempPath = await VideoThumbnail.thumbnailFile(
            video: file.absolute.path,
            imageFormat: ImageFormat.JPEG,
            maxWidth: 256,
            quality: 60,
          );
          if (tempPath != null) {
            thumbBytes = await File(tempPath).readAsBytes();
          }
        }
      }
    } catch (e) {
      print('Thumbnail error: $e');
    }

    if (thumbBytes != null) {
       return Response.ok(thumbBytes, headers: {...headers, 'content-type': 'image/jpeg'});
    } else {
       // Return 204 No Content or a generic fallback if failed, so client handles it
       // Or 404 to trigger fallback icon
       return Response.notFound('Could not generate thumbnail', headers: headers);
    }
  }
  
  Future<Response> _handleDownload(String filePath, Map<String, String> headers) async {
    final file = File(filePath);
    if (!file.existsSync()) return Response.notFound('File not found', headers: headers);
    
    final size = await file.length();
    final filename = p.basename(filePath);
    
    return Response.ok(
      file.openRead(), 
      headers: {
        ...headers,
        'content-type': 'application/octet-stream',
        'content-length': size.toString(),
        'content-disposition': 'attachment; filename="$filename"',
      }
    );
  }

  Future<Response> _handleDelete(String targetPath, Map<String, String> headers) async {
    try {
      if (FileSystemEntity.isDirectorySync(targetPath)) {
        Directory(targetPath).deleteSync(recursive: true);
      } else if (FileSystemEntity.isFileSync(targetPath)) {
        File(targetPath).deleteSync();
      } else {
        return Response.notFound('Path not found', headers: headers);
      }
      return Response.ok(jsonEncode({'success': true}), headers: headers);
    } catch (e) {
      return Response.internalServerError(body: 'Delete failed: $e', headers: headers);
    }
  }

  Future<Response> _handleRename(String targetPath, String newName, Map<String, String> headers) async {
    try {
      final parent = p.dirname(targetPath);
      final newPath = p.join(parent, newName);
      
      // Safety: ensure newPath is still safe
      if (!_isSafePath(newPath)) return Response.forbidden('Invalid name', headers: headers);

      final type = FileSystemEntity.typeSync(targetPath);
      if (type == FileSystemEntityType.notFound) return Response.notFound('Source not found', headers: headers);
      
      if (type == FileSystemEntityType.directory) {
        Directory(targetPath).renameSync(newPath);
      } else {
        File(targetPath).renameSync(newPath);
      }
       return Response.ok(jsonEncode({'success': true}), headers: headers);
    } catch (e) {
      return Response.internalServerError(body: 'Rename failed: $e', headers: headers);
    }
  }

  Future<Response> _handleCreateDir(String targetPath, Map<String, String> headers) async {
    try {
      final dir = Directory(targetPath);
      if (dir.existsSync()) {
        return Response.badRequest(body: 'Directory already exists', headers: headers);
      }
      dir.createSync(recursive: true);
      return Response.ok(jsonEncode({'success': true}), headers: headers);
    } catch (e) {
      return Response.internalServerError(body: 'Create failed: $e', headers: headers);
    }
  }
}

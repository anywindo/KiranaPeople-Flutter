import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../config/api_config.dart';
import '../storage/secure_storage_service.dart';

class FileDownloadResult {
  final bool isSuccess;
  final String? savedPath;
  final String fileName;
  final String? errorMessage;

  const FileDownloadResult({
    required this.isSuccess,
    required this.fileName,
    this.savedPath,
    this.errorMessage,
  });
}

class FileDownloadHelper {
  /// Sanitizes a filename to prevent path traversal attacks (CWE-22)
  /// and invalid filesystem characters.
  static String sanitizeFileName(String fileName, {String? defaultName}) {
    var clean = fileName.trim();
    // Replace URL-encoded directory separators if any
    clean = clean.replaceAll('%2f', '_').replaceAll('%2F', '_');
    clean = clean.replaceAll('%5c', '_').replaceAll('%5C', '_');
    // Strip all path delimiters (forward slash, backslash)
    clean = clean.replaceAll(RegExp(r'[/\\]+'), '_');
    // Remove directory traversal dots (e.g. .., ..., /../, \..\)
    clean = clean.replaceAll(RegExp(r'\.{2,}'), '.');
    // Strip leading dot, underscore, or space to prevent hidden files or root dots
    clean = clean.replaceAll(RegExp(r'^[\._\s]+'), '');
    // Remove control characters and illegal filesystem characters
    clean = clean.replaceAll(RegExp(r'[\x00-\x1F\x7F<>:"|?*]'), '_');
    clean = clean.trim();

    if (clean.isEmpty || clean == '.' || !clean.contains('.')) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return defaultName ?? 'kirana_media_$timestamp.jpg';
    }
    return clean;
  }

  /// SECURITY (SEC-15): Validates whether a target URL belongs to the trusted API host.
  /// Bearer tokens are NEVER attached to third-party or untrusted domains to prevent token theft.
  static bool isTrustedHost(String urlOrPath) => ApiConfig.isTrustedHost(urlOrPath);

  /// Extracts the original filename from a URL or file path and sanitizes it.
  static String extractFileName(String urlOrPath, {String? defaultName}) {
    String? rawName;
    try {
      final cleanUrl = urlOrPath.split('?').first.split('#').first;
      final uri = Uri.tryParse(cleanUrl);
      String? segment = uri?.pathSegments.isNotEmpty == true
          ? uri!.pathSegments.last
          : null;
      if (segment != null &&
          segment.trim().isNotEmpty &&
          segment.contains('.')) {
        rawName = Uri.decodeComponent(segment.trim());
      }
    } catch (_) {}

    if (rawName != null && rawName.isNotEmpty) {
      return sanitizeFileName(rawName, defaultName: defaultName);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return defaultName ?? 'kirana_media_$timestamp.jpg';
  }

  /// Resolves full URL if relative.
  static String resolveFullUrl(String urlOrPath) {
    final trimmed = urlOrPath.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('/storage') ||
        trimmed.startsWith('/data') ||
        trimmed.startsWith('/Users') ||
        trimmed.contains(RegExp(r'^[a-zA-Z]:\\'))) {
      return trimmed; // Local path
    }
    // Relative URL from backend
    final origin = ApiConfig.cachedHostOrigin;
    if (trimmed.startsWith('/')) {
      return '$origin$trimmed';
    }
    return '$origin/$trimmed';
  }

  /// Determines the appropriate download directory across Android, iOS, and Desktop.
  static Future<Directory> getDownloadDirectory() async {
    if (!kIsWeb && Platform.isAndroid) {
      final publicDownload = Directory('/storage/emulated/0/Download');
      if (await publicDownload.exists()) {
        return publicDownload;
      }
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null && await downloadsDir.exists()) {
        return downloadsDir;
      }
      final extDir = await getExternalStorageDirectory();
      if (extDir != null && await extDir.exists()) {
        return extDir;
      }
      return await getApplicationDocumentsDirectory();
    } else if (!kIsWeb && Platform.isIOS) {
      return await getApplicationDocumentsDirectory();
    } else {
      // Desktop (macOS, Windows, Linux)
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null) {
        return downloadsDir;
      }
      return await getApplicationDocumentsDirectory();
    }
  }

  /// Downloads and saves the previewed file while retaining original bytes, format, and filename.
  static Future<FileDownloadResult> downloadFile({
    required String urlOrPath,
    String? customFileName,
    Dio? dioClient,
  }) async {
    if (urlOrPath.trim().isEmpty) {
      return const FileDownloadResult(
        isSuccess: false,
        fileName: '',
        errorMessage: 'URL atau path file tidak valid.',
      );
    }

    final fullUrl = resolveFullUrl(urlOrPath);
    final rawFileName = customFileName ?? extractFileName(fullUrl);
    final fileName = sanitizeFileName(rawFileName);

    try {
      List<int> bytes;

      if (fullUrl.startsWith('http://') || fullUrl.startsWith('https://')) {
        // 1. Try reading from cached image first for instant download
        File? cachedFile;
        try {
          final fileInfo = await DefaultCacheManager().getFileFromCache(
            fullUrl,
          );
          if (fileInfo != null && await fileInfo.file.exists()) {
            cachedFile = fileInfo.file;
          }
        } catch (_) {}

        if (cachedFile != null) {
          bytes = await cachedFile.readAsBytes();
        } else {
          // 2. Fetch directly from network
          final dio = dioClient ??
              Dio(
                BaseOptions(
                  connectTimeout: const Duration(seconds: 30),
                  receiveTimeout: const Duration(seconds: 30),
                  sendTimeout: const Duration(seconds: 30),
                ),
              );
          final headers = <String, dynamic>{};
          // SECURITY (SEC-15): Only attach authorization header if target host is trusted
          if (isTrustedHost(fullUrl)) {
            final token = await SecureStorageService().getToken();
            if (token != null && token.isNotEmpty) {
              headers['Authorization'] = 'Bearer $token';
            }
          }

          final response = await dio.get<List<int>>(
            fullUrl,
            options: Options(
              responseType: ResponseType.bytes,
              headers: headers,
              sendTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
            ),
          );

          if (response.data == null || response.data!.isEmpty) {
            return FileDownloadResult(
              isSuccess: false,
              fileName: fileName,
              errorMessage: 'Data file kosong atau gagal diunduh.',
            );
          }
          bytes = response.data!;
        }
      } else {
        // Local file
        final localFile = File(fullUrl);
        if (!await localFile.exists()) {
          return FileDownloadResult(
            isSuccess: false,
            fileName: fileName,
            errorMessage: 'File lokal tidak ditemukan.',
          );
        }
        bytes = await localFile.readAsBytes();
      }

      // Save to directory with collision avoidance
      final dir = await getDownloadDirectory();
      final destinationFile = _getUniqueFile(dir.path, fileName);
      await destinationFile.writeAsBytes(bytes, flush: true);

      return FileDownloadResult(
        isSuccess: true,
        fileName: destinationFile.uri.pathSegments.last,
        savedPath: destinationFile.path,
      );
    } catch (e) {
      return FileDownloadResult(
        isSuccess: false,
        fileName: fileName,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  static File _getUniqueFile(String directoryPath, String fileName) {
    final safeName = sanitizeFileName(fileName);
    var file = File('$directoryPath/$safeName');
    if (!file.existsSync()) return file;

    final dotIndex = safeName.lastIndexOf('.');
    final name = dotIndex != -1 ? safeName.substring(0, dotIndex) : safeName;
    final ext = dotIndex != -1 ? safeName.substring(dotIndex) : '';

    var counter = 1;
    while (file.existsSync()) {
      file = File('$directoryPath/${name}_$counter$ext');
      counter++;
    }
    return file;
  }

  /// Shares the previewed file or media directly via system share sheet.
  static Future<FileDownloadResult> shareFile({
    required String urlOrPath,
    String? customFileName,
    String? shareSubject,
    Dio? dioClient,
  }) async {
    if (urlOrPath.trim().isEmpty) {
      return const FileDownloadResult(
        isSuccess: false,
        fileName: '',
        errorMessage: 'URL atau path file tidak valid.',
      );
    }

    final fullUrl = resolveFullUrl(urlOrPath);
    final rawFileName = customFileName ?? extractFileName(fullUrl);
    final fileName = sanitizeFileName(rawFileName);

    try {
      String localFilePath;

      if (fullUrl.startsWith('http://') || fullUrl.startsWith('https://')) {
        // 1. Check cached image first
        File? cachedFile;
        try {
          final fileInfo = await DefaultCacheManager().getFileFromCache(
            fullUrl,
          );
          if (fileInfo != null && await fileInfo.file.exists()) {
            cachedFile = fileInfo.file;
          }
        } catch (_) {}

        if (cachedFile != null) {
          // Copy to temp directory with proper extension/filename if needed
          final tempDir = await getTemporaryDirectory();
          final target = File('${tempDir.path}/$fileName');
          await cachedFile.copy(target.path);
          localFilePath = target.path;
        } else {
          // 2. Fetch directly from network and save to temp file
          final dio = dioClient ??
              Dio(
                BaseOptions(
                  connectTimeout: const Duration(seconds: 30),
                  receiveTimeout: const Duration(seconds: 30),
                  sendTimeout: const Duration(seconds: 30),
                ),
              );
          final headers = <String, dynamic>{};
          // SECURITY (SEC-15): Only attach authorization header if target host is trusted
          if (isTrustedHost(fullUrl)) {
            final token = await SecureStorageService().getToken();
            if (token != null && token.isNotEmpty) {
              headers['Authorization'] = 'Bearer $token';
            }
          }

          final tempDir = await getTemporaryDirectory();
          final tempFile = File('${tempDir.path}/$fileName');

          await dio.download(
            fullUrl,
            tempFile.path,
            options: Options(headers: headers),
          );

          if (!await tempFile.exists()) {
            return FileDownloadResult(
              isSuccess: false,
              fileName: fileName,
              errorMessage: 'Gagal mengunduh file untuk dibagikan.',
            );
          }
          localFilePath = tempFile.path;
        }
      } else {
        // Local file
        final localFile = File(fullUrl);
        if (!await localFile.exists()) {
          return FileDownloadResult(
            isSuccess: false,
            fileName: fileName,
            errorMessage: 'File lokal tidak ditemukan.',
          );
        }
        localFilePath = localFile.path;
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(localFilePath)],
          subject: shareSubject ?? fileName,
        ),
      );

      return FileDownloadResult(
        isSuccess: true,
        fileName: fileName,
        savedPath: localFilePath,
      );
    } catch (e) {
      return FileDownloadResult(
        isSuccess: false,
        fileName: fileName,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}

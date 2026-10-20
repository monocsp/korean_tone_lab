import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Model metadata and file management for Qwen3-0.6B GGUF.
/// Supports local project paths, iOS/Android sandbox Documents directory,
/// automatic sync, and direct HuggingFace download.
class ModelManager {
  static const String modelFileName = 'Qwen_Qwen3-0.6B-Q4_K_M.gguf';
  static const String modelRepoUrl =
      'https://huggingface.co/bartowski/Qwen_Qwen3-0.6B-GGUF/resolve/main/Qwen_Qwen3-0.6B-Q4_K_M.gguf';
  static const int expectedSizeBytes = 484220320; // 461.79 MB

  final String? customModelPath;
  File? _cachedModelFile;

  ModelManager({this.customModelPath});

  /// Synchronous fallback for legacy or instant checks.
  File getModelFile() {
    if (_cachedModelFile != null && _cachedModelFile!.existsSync()) {
      return _cachedModelFile!;
    }
    if (customModelPath != null && customModelPath!.isNotEmpty) {
      return File(customModelPath!);
    }

    final candidatePaths = [
      'models/$modelFileName',
      '../models/$modelFileName',
      '../../models/$modelFileName',
      '/Users/pcs/github/korean_tone_lab/models/$modelFileName',
    ];

    for (final p in candidatePaths) {
      final f = File(p);
      if (f.existsSync() && f.lengthSync() > 1000000) {
        _cachedModelFile = f;
        return f;
      }
    }

    return File('models/$modelFileName');
  }

  /// Asynchronously resolves the model file path across application documents directory,
  /// sandbox paths, and development host paths.
  Future<File> resolveModelFile() async {
    if (customModelPath != null && customModelPath!.isNotEmpty) {
      final f = File(customModelPath!);
      if (await f.exists()) {
        _cachedModelFile = f;
        return f;
      }
    }

    // 1. Check App Documents directory (standard iOS / Android sandbox)
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final inDocModel = File('${appDocDir.path}/models/$modelFileName');
      if (await inDocModel.exists() && (await inDocModel.length()) > 10000000) {
        _cachedModelFile = inDocModel;
        return inDocModel;
      }

      final inDocRootModel = File('${appDocDir.path}/$modelFileName');
      if (await inDocRootModel.exists() && (await inDocRootModel.length()) > 10000000) {
        _cachedModelFile = inDocRootModel;
        return inDocRootModel;
      }
    } catch (e) {
      debugPrint('[ModelManager] getApplicationDocumentsDirectory error: $e');
    }

    // 2. Check Host / Mac filesystem candidates
    final candidatePaths = [
      'models/$modelFileName',
      '../models/$modelFileName',
      '../../models/$modelFileName',
      '/Users/pcs/github/korean_tone_lab/models/$modelFileName',
    ];

    for (final p in candidatePaths) {
      final f = File(p);
      if (await f.exists() && (await f.length()) > 10000000) {
        _cachedModelFile = f;
        return f;
      }
    }

    // Default target path in App Documents directory
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      return File('${appDocDir.path}/models/$modelFileName');
    } catch (_) {
      return File('models/$modelFileName');
    }
  }

  /// Checks if the model file is physically available and valid (> 10MB).
  Future<bool> checkModelAvailable() async {
    final file = await resolveModelFile();
    if (await file.exists()) {
      final len = await file.length();
      return len > 10000000;
    }
    return false;
  }

  /// Synchronous availability check.
  bool isModelAvailable() {
    final file = getModelFile();
    return file.existsSync() && file.lengthSync() > 10000000;
  }

  /// Returns current file size in bytes asynchronously.
  Future<int> getFileSizeBytes() async {
    final file = await resolveModelFile();
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  /// Returns human-readable size string.
  Future<String> getFormattedFileSizeAsync() async {
    final bytes = await getFileSizeBytes();
    if (bytes == 0) return '0 MB (미설치)';
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  /// Synchronous formatted file size.
  String getFormattedFileSize() {
    final file = getModelFile();
    if (file.existsSync()) {
      final mb = file.lengthSync() / (1024 * 1024);
      return '${mb.toStringAsFixed(1)} MB';
    }
    return '0 MB (미설치)';
  }

  /// Auto-sync: if host model exists and sandbox doesn't have it, copy to sandbox.
  Future<bool> syncModelToSandboxIfAvailable() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final targetDir = Directory('${appDocDir.path}/models');
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }
      final targetFile = File('${targetDir.path}/$modelFileName');

      if (await targetFile.exists() && (await targetFile.length()) > 10000000) {
        _cachedModelFile = targetFile;
        return true;
      }

      // Check if host file exists
      const hostPath = '/Users/pcs/github/korean_tone_lab/models/$modelFileName';
      final hostFile = File(hostPath);
      if (await hostFile.exists() && (await hostFile.length()) > 10000000) {
        debugPrint('[ModelManager] Copying host model to sandbox: ${targetFile.path}');
        await hostFile.copy(targetFile.path);
        _cachedModelFile = targetFile;
        return true;
      }
    } catch (e) {
      debugPrint('[ModelManager] syncModelToSandbox error: $e');
    }
    return false;
  }

  /// Downloads the model file from Hugging Face directly to sandbox Documents.
  Future<File> downloadModel({void Function(double progress)? onProgress}) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final targetDir = Directory('${appDocDir.path}/models');
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }
    final targetFile = File('${targetDir.path}/$modelFileName');
    final tempFile = File('${targetDir.path}/$modelFileName.tmp');

    if (await tempFile.exists()) {
      await tempFile.delete();
    }

    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(modelRepoUrl));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw HttpException('Download failed: HTTP ${response.statusCode}');
      }

      final totalBytes = response.contentLength > 0 ? response.contentLength : expectedSizeBytes;
      int downloadedBytes = 0;

      final sink = tempFile.openWrite();
      await for (final chunk in response) {
        sink.add(chunk);
        downloadedBytes += chunk.length;
        if (onProgress != null && totalBytes > 0) {
          onProgress(downloadedBytes / totalBytes);
        }
      }
      await sink.flush();
      await sink.close();

      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      await tempFile.rename(targetFile.path);
      _cachedModelFile = targetFile;
      return targetFile;
    } finally {
      client.close();
    }
  }
}

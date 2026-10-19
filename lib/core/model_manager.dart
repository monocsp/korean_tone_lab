import 'dart:io';

/// Model metadata and file management for Qwen3-0.6B GGUF.
class ModelManager {
  static const String modelFileName = 'Qwen_Qwen3-0.6B-Q4_K_M.gguf';
  static const int expectedSizeBytes = 484220320; // 461.79 MB

  final String? customModelPath;

  ModelManager({this.customModelPath});

  /// Finds the candidate local model path.
  File getModelFile() {
    if (customModelPath != null && customModelPath!.isNotEmpty) {
      return File(customModelPath!);
    }

    // Try relative project paths or working directory
    final pathsToTry = [
      'models/$modelFileName',
      '../models/$modelFileName',
      '../../models/$modelFileName',
      '/Users/pcs/github/korean_tone_lab/models/$modelFileName',
    ];

    for (final p in pathsToTry) {
      final f = File(p);
      if (f.existsSync()) {
        return f;
      }
    }

    return File('models/$modelFileName');
  }

  /// Checks if the model file is physically available on device.
  bool isModelAvailable() {
    final file = getModelFile();
    return file.existsSync() && file.lengthSync() > 1000000;
  }

  /// Returns current file size in bytes.
  int getFileSize() {
    final file = getModelFile();
    if (file.existsSync()) {
      return file.lengthSync();
    }
    return 0;
  }

  /// Returns human-readable size string.
  String getFormattedFileSize() {
    final bytes = getFileSize();
    if (bytes == 0) return '0 MB (미설치)';
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }
}

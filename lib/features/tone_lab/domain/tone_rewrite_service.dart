import 'tone_rewrite_request.dart';
import 'tone_rewrite_result.dart';

/// Abstract service contract for Korean tone rewriting.
abstract class ToneRewriteService {
  /// Whether the engine/model is loaded and ready.
  bool get isModelLoaded;

  /// Human-readable name of the engine (e.g., 'Qwen3-0.6B Q4_K_M (Local Metal)' or 'Mock Tone Engine').
  String get engineName;

  /// Initializes or warms up the model/runtime.
  Future<void> initialize();

  /// Executes text-to-text rewriting on the request.
  Future<ToneRewriteResult> rewrite(ToneRewriteRequest request);

  /// Releases resources.
  Future<void> dispose();
}

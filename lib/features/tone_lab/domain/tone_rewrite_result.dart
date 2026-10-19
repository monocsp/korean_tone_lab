/// Result object containing the rewritten text, validation, and performance metrics.
class ToneRewriteResult {
  final String rewrittenText;
  final String rawOutput;
  final bool usedFallback;
  final String? fallbackReason;
  final int latencyMs;
  final double tokensPerSec;
  final List<String> validatorFlags;
  final bool isMock;
  final Map<String, dynamic> modelMetadata;

  const ToneRewriteResult({
    required this.rewrittenText,
    required this.rawOutput,
    required this.usedFallback,
    this.fallbackReason,
    required this.latencyMs,
    required this.tokensPerSec,
    this.validatorFlags = const [],
    required this.isMock,
    this.modelMetadata = const {},
  });

  factory ToneRewriteResult.fallback({
    required String originalText,
    required String reason,
    required int latencyMs,
    required bool isMock,
    List<String> flags = const [],
  }) {
    return ToneRewriteResult(
      rewrittenText: originalText,
      rawOutput: originalText,
      usedFallback: true,
      fallbackReason: reason,
      latencyMs: latencyMs,
      tokensPerSec: 0.0,
      validatorFlags: flags,
      isMock: isMock,
      modelMetadata: {'status': 'FALLBACK_TRIGGERED'},
    );
  }
}

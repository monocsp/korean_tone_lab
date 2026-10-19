import 'dart:async';
import '../domain/tone_rewrite_request.dart';
import '../domain/tone_rewrite_result.dart';
import '../domain/tone_rewrite_service.dart';
import '../domain/tone_style.dart';
import 'fact_preservation_validator.dart';

/// Mock service for testing and offline fallback simulation.
/// Clearly flagged with isMock = true to prevent deceptive reporting.
class MockToneRewriteService implements ToneRewriteService {
  final FactPreservationValidator _validator;
  bool _isLoaded = false;

  MockToneRewriteService({FactPreservationValidator? validator})
      : _validator = validator ?? FactPreservationValidator();

  @override
  bool get isModelLoaded => _isLoaded;

  @override
  String get engineName => 'Mock Rule-based Simulator (Not On-device LLM)';

  @override
  Future<void> initialize() async {
    await Future.delayed(const Duration(milliseconds: 150));
    _isLoaded = true;
  }

  @override
  Future<ToneRewriteResult> rewrite(ToneRewriteRequest request) async {
    final stopwatch = Stopwatch()..start();
    await Future.delayed(const Duration(milliseconds: 280)); // Simulate inference latency

    String rewritten = request.sourceText;

    // Apply rule-based mock rewrites based on style
    switch (request.style) {
      case ToneStyleType.naturalKorean:
        rewritten = rewritten
            .replaceAll('네, 맞습니다. ', '')
            .replaceAll('관하여 말씀드리자면, ', '')
            .replaceAll('진행하시는 것을 추천해 드립니다', '해보시는 걸 추천해요')
            .replaceAll('사료됩니다', '생각돼요')
            .replaceAll('수행하십시오', '해보세요')
            .replaceAll('취해보십시오', '해보세요');
        break;

      case ToneStyleType.warmFriend:
        rewritten = rewritten
            .replaceAll('네, 맞습니다. ', '응, ')
            .replaceAll('하십시요', '해')
            .replaceAll('하십시오', '해')
            .replaceAll('권고드립니다', '추천할게')
            .replaceAll('바랍니다', '좋겠어')
            .replaceAll('드립니다', '줄게')
            .replaceAll('사료됩니다', '것 같아')
            .replaceAll('있습니다', '있어')
            .replaceAll('입니다', '이야')
            .replaceAll('해요', '해');
        break;

      case ToneStyleType.playfulFriend:
        rewritten = rewritten
            .replaceAll('네, 맞습니다. ', '당연하지! ')
            .replaceAll('하십시요', '해봐라')
            .replaceAll('하십시오', '하자')
            .replaceAll('있습니다', '있거든?')
            .replaceAll('입니다', '이잖아')
            .replaceAll('해요', '해버려')
            .replaceAll('드립니다', '줄 테니 기대해');
        break;
    }

    stopwatch.stop();

    final validation = _validator.validate(
      request.sourceText,
      rewritten,
      protectedFacts: request.protectedFacts,
    );

    if (!validation.isValid) {
      return ToneRewriteResult.fallback(
        originalText: request.sourceText,
        reason: validation.reason,
        latencyMs: stopwatch.elapsedMilliseconds,
        isMock: true,
        flags: validation.flags,
      );
    }

    return ToneRewriteResult(
      rewrittenText: rewritten,
      rawOutput: rewritten,
      usedFallback: false,
      latencyMs: stopwatch.elapsedMilliseconds,
      tokensPerSec: 180.0,
      validatorFlags: validation.flags,
      isMock: true,
      modelMetadata: {
        'simulator': 'Regex Rule-based',
        'style': request.style.id,
      },
    );
  }

  @override
  Future<void> dispose() async {
    _isLoaded = false;
  }
}

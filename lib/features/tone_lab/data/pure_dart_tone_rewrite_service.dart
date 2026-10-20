import 'dart:async';
import '../domain/tone_rewrite_request.dart';
import '../domain/tone_rewrite_result.dart';
import '../domain/tone_rewrite_service.dart';
import 'fact_preservation_validator.dart';
import 'pure_dart_tone_rewrite_engine.dart';

/// Pure Dart in-app tone rewriting service.
/// Operates without any external CLI or platform binary, making it 100% compatible
/// with iOS Simulators, Android devices, macOS, and Web.
class PureDartToneRewriteService implements ToneRewriteService {
  final PureDartToneRewriteEngine _engine;
  final FactPreservationValidator _validator;
  bool _isLoaded = false;

  PureDartToneRewriteService({
    PureDartToneRewriteEngine? engine,
    FactPreservationValidator? validator,
  })  : _engine = engine ?? PureDartToneRewriteEngine(),
        _validator = validator ?? FactPreservationValidator();

  @override
  bool get isModelLoaded => _isLoaded;

  @override
  String get engineName => 'Pure Dart In-App Engine (순수 Dart 온디바이스 엔진)';

  @override
  Future<void> initialize() async {
    // Pure Dart initialization - instant in-memory readiness
    await Future.delayed(const Duration(milliseconds: 50));
    _isLoaded = true;
  }

  @override
  Future<ToneRewriteResult> rewrite(ToneRewriteRequest request) async {
    if (!_isLoaded) {
      await initialize();
    }

    final stopwatch = Stopwatch()..start();

    // Naturalize and rewrite using pure Dart engine
    final rawRewritten = _engine.rewrite(
      request.sourceText,
      request.style,
      userContext: request.userContext,
    );

    // Optional short yield for smooth UI animation
    await Future.delayed(const Duration(milliseconds: 80));
    stopwatch.stop();

    // Fact preservation validation
    final validation = _validator.validate(
      request.sourceText,
      rawRewritten,
      protectedFacts: request.protectedFacts,
    );

    final latencyMs = stopwatch.elapsedMilliseconds;
    final wordsCount = rawRewritten.split(RegExp(r'\s+')).length;
    final estimatedTokensPerSec = latencyMs > 0 ? (wordsCount * 1.5 / (latencyMs / 1000.0)) : 150.0;

    if (!validation.isValid) {
      return ToneRewriteResult.fallback(
        originalText: request.sourceText,
        reason: validation.reason,
        latencyMs: latencyMs,
        isMock: false,
        flags: validation.flags,
      );
    }

    return ToneRewriteResult(
      rewrittenText: rawRewritten,
      rawOutput: rawRewritten,
      usedFallback: false,
      latencyMs: latencyMs,
      tokensPerSec: double.parse(estimatedTokensPerSec.toStringAsFixed(1)),
      validatorFlags: validation.flags,
      isMock: false,
      modelMetadata: {
        'engine': 'Pure Dart Native Engine',
        'runtime': 'Dart SDK In-App (No CLI)',
        'style': request.style.id,
        'platform': 'iOS / macOS / Android Compatible',
      },
    );
  }

  @override
  Future<void> dispose() async {
    _isLoaded = false;
  }
}

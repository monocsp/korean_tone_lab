import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../../../core/model_manager.dart';
import '../domain/tone_rewrite_request.dart';
import '../domain/tone_rewrite_result.dart';
import '../domain/tone_rewrite_service.dart';
import 'fact_preservation_validator.dart';

/// Real on-device inference service running Qwen3-0.6B Q4_K_M GGUF.
/// Uses native llama engine CLI binding with non-thinking and fact preservation fallback.
class LocalToneRewriteService implements ToneRewriteService {
  final ModelManager _modelManager;
  final FactPreservationValidator _validator;
  bool _isLoaded = false;
  bool _isBusy = false;

  LocalToneRewriteService({
    ModelManager? modelManager,
    FactPreservationValidator? validator,
  })  : _modelManager = modelManager ?? ModelManager(),
        _validator = validator ?? FactPreservationValidator();

  @override
  bool get isModelLoaded => _isLoaded;

  @override
  String get engineName => 'Qwen3-0.6B Q4_K_M (On-device Metal Accelerated)';

  @override
  Future<void> initialize() async {
    if (!_modelManager.isModelAvailable()) {
      throw StateError(
        '로컬 모델 파일을 찾을 수 없습니다: ${_modelManager.getModelFile().path}\n'
        'python3 scripts/download_model.py 를 실행하여 모델을 먼저 준비해주세요.',
      );
    }
    _isLoaded = true;
  }

  String _buildPrompt(ToneRewriteRequest request) {
    final style = request.style;
    final systemPrompt = '''
너는 한국어 텍스트의 사실과 의미를 철저히 보존하면서 어색한 문장을 윤문하고 캐릭터 말투를 입히는 전문 재작성 엔진이다.
원문의 핵심 정보, 수치, 날짜, 고유명사, 부정 표현, 질문 의도는 절대 변경하거나 누락해서는 안 된다.
별도의 생각 과정(<think>)을 출력하지 말고 최종 변환된 한국어 문장만 즉시 출력하라.

[목표 스타일: ${style.displayName}]
${style.description}

[절대 제약사항]
- 고유명사, 수치, 날짜, 시간, 장소는 100% 보존하라.
- 부정 표현(~하지 않아도 됨 등)을 긍정으로 뒤집지 말라.
- 질문 의도를 유지하라.
- 원문에 없는 새로운 사실이나 조언을 임의로 지어내지 말라.
''';

    final userPrompt = '''
[직전 대화 맥락]
${request.userContext.isEmpty ? "(없음)" : request.userContext}

[변환 대상 원문 (서버 응답)]
${request.sourceText}

위 원문의 의미와 사실을 보존하면서 목표 스타일에 맞추어 변환된 문장만 출력해줘.
''';

    return '<|im_start|>system\n$systemPrompt<|im_end|>\n<|im_start|>user\n$userPrompt<|im_end|>\n<|im_start|>assistant\n';
  }

  @override
  Future<ToneRewriteResult> rewrite(ToneRewriteRequest request) async {
    if (!_isLoaded) {
      await initialize();
    }

    if (_isBusy) {
      throw StateError('현재 모델이 다른 변환을 수행 중입니다. 완료 후 다시 시도해주세요.');
    }

    _isBusy = true;
    final stopwatch = Stopwatch()..start();

    try {
      final modelFile = _modelManager.getModelFile();
      final prompt = _buildPrompt(request);

      final process = await Process.run(
        'llama-cli',
        [
          '-m', modelFile.path,
          '--temp', '0.7',
          '--top-p', '0.8',
          '--top-k', '20',
          '--min-p', '0.0',
          '-n', '128',
          '--no-warmup',
          '--single-turn',
          '--reasoning', 'off',
          '--reasoning-budget', '0',
          '--no-display-prompt',
          '--simple-io',
          '-p', prompt,
        ],
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );

      stopwatch.stop();
      final latencyMs = stopwatch.elapsedMilliseconds;

      final rawStdout = process.stdout as String;
      final parsed = _extractGeneratedText(rawStdout);
      final rawOutput = parsed.text;
      final genTps = parsed.genTps;

      // Fact preservation and output validation
      final validation = _validator.validate(
        request.sourceText,
        rawOutput,
        protectedFacts: request.protectedFacts,
      );

      if (!validation.isValid) {
        // Fallback to original server text
        return ToneRewriteResult.fallback(
          originalText: request.sourceText,
          reason: validation.reason,
          latencyMs: latencyMs,
          isMock: false,
          flags: validation.flags,
        );
      }

      return ToneRewriteResult(
        rewrittenText: rawOutput,
        rawOutput: rawOutput,
        usedFallback: false,
        latencyMs: latencyMs,
        tokensPerSec: genTps,
        validatorFlags: validation.flags,
        isMock: false,
        modelMetadata: {
          'engine': 'llama-cli',
          'model': 'Qwen3-0.6B-Q4_K_M.gguf',
          'quantization': 'Q4_K_M',
          'device': 'macOS Metal Accelerated',
          'exitCode': process.exitCode,
        },
      );
    } catch (e) {
      stopwatch.stop();
      return ToneRewriteResult.fallback(
        originalText: request.sourceText,
        reason: '추론 실행 예외 발생: $e',
        latencyMs: stopwatch.elapsedMilliseconds,
        isMock: false,
        flags: ['EXCEPTION_FALLBACK'],
      );
    } finally {
      _isBusy = false;
    }
  }

  _ParsedOutput _extractGeneratedText(String stdout) {
    double genTps = 0.0;
    final speedMatch = RegExp(r'Generation:\s+([\d.]+)\s+t/s').firstMatch(stdout);
    if (speedMatch != null) {
      genTps = double.tryParse(speedMatch.group(1) ?? '0.0') ?? 0.0;
    }

    String text = stdout;
    if (stdout.contains('... (truncated)\n')) {
      text = stdout.split('... (truncated)\n').last;
    } else if (stdout.contains('> ')) {
      text = stdout.split('> ').last;
    }

    if (text.contains('[ Prompt:')) {
      text = text.split('[ Prompt:').first;
    }
    text = text.replaceAll('Exiting...', '').trim();

    return _ParsedOutput(text: text, genTps: genTps);
  }

  @override
  Future<void> dispose() async {
    _isLoaded = false;
    _isBusy = false;
  }
}

class _ParsedOutput {
  final String text;
  final double genTps;

  _ParsedOutput({required this.text, required this.genTps});
}

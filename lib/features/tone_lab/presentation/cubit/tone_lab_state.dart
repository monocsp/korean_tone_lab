import '../../domain/tone_rewrite_result.dart';
import '../../domain/tone_style.dart';

enum ToneLabStatus { initial, loading, success, failure }

enum EngineMode {
  pureDart('pure_dart', '순수 Dart 인앱 엔진 (모바일/시뮬레이터 최적)'),
  localGguf('local_gguf', '온디바이스 Qwen3 GGUF (Metal 가속)'),
  mock('mock', 'Mock 모의 서비스');

  final String id;
  final String displayName;
  const EngineMode(this.id, this.displayName);
}

class ToneLabState {
  final ToneLabStatus status;
  final String sourceText;
  final String userContext;
  final ToneStyleType selectedStyle;
  final EngineMode engineMode;
  final ToneRewriteResult? result;
  final String? errorMessage;
  final bool isGgufModelReady;
  final String modelFileSize;
  final List<String> protectedFacts;

  const ToneLabState({
    this.status = ToneLabStatus.initial,
    this.sourceText = '',
    this.userContext = '',
    this.selectedStyle = ToneStyleType.warmFriend,
    this.engineMode = EngineMode.pureDart,
    this.result,
    this.errorMessage,
    this.isGgufModelReady = false,
    this.modelFileSize = '0 MB',
    this.protectedFacts = const [],
  });

  ToneLabState copyWith({
    ToneLabStatus? status,
    String? sourceText,
    String? userContext,
    ToneStyleType? selectedStyle,
    EngineMode? engineMode,
    ToneRewriteResult? result,
    String? errorMessage,
    bool? isGgufModelReady,
    String? modelFileSize,
    List<String>? protectedFacts,
  }) {
    return ToneLabState(
      status: status ?? this.status,
      sourceText: sourceText ?? this.sourceText,
      userContext: userContext ?? this.userContext,
      selectedStyle: selectedStyle ?? this.selectedStyle,
      engineMode: engineMode ?? this.engineMode,
      result: result ?? this.result,
      errorMessage: errorMessage,
      isGgufModelReady: isGgufModelReady ?? this.isGgufModelReady,
      modelFileSize: modelFileSize ?? this.modelFileSize,
      protectedFacts: protectedFacts ?? this.protectedFacts,
    );
  }
}

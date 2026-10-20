import '../../domain/tone_rewrite_result.dart';
import '../../domain/tone_style.dart';

enum ToneLabStatus { initial, loading, success, failure }

enum EngineMode {
  localGguf(
    'local_gguf',
    '🧠 Qwen3-0.6B Q4_K_M (온디바이스 LLM 신경망)',
    '실제 461.8MB GGUF 인공신경망 가중치를 로드하여 문맥과 뉘앙스를 온디바이스에서 생성합니다.',
  ),
  pureDart(
    'pure_dart',
    '⚡ Qwen3 경량 규칙 엔진 (정규식·문법 규칙 기반)',
    '가중치 파일 다운로드 없이 수치·부정 보존 및 종결 어미를 정규식/문법 사전 규칙으로 초고속(1ms) 변환합니다.',
  ),
  mock(
    'mock',
    '🛠 Mock 모의 테스트 엔진',
    '네트워크 및 모델 가중치 없이 UI/UX 동작을 확인하기 위한 개발/테스트용 모의 엔진입니다.',
  );

  final String id;
  final String displayName;
  final String description;
  const EngineMode(this.id, this.displayName, this.description);
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
  final bool isDownloadingModel;
  final double downloadProgress;

  const ToneLabState({
    this.status = ToneLabStatus.initial,
    this.sourceText = '',
    this.userContext = '',
    this.selectedStyle = ToneStyleType.warmFriend,
    this.engineMode = EngineMode.pureDart,
    this.result,
    this.errorMessage,
    this.isGgufModelReady = false,
    this.modelFileSize = '0 MB (확인 중)',
    this.protectedFacts = const [],
    this.isDownloadingModel = false,
    this.downloadProgress = 0.0,
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
    bool? isDownloadingModel,
    double? downloadProgress,
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
      isDownloadingModel: isDownloadingModel ?? this.isDownloadingModel,
      downloadProgress: downloadProgress ?? this.downloadProgress,
    );
  }
}

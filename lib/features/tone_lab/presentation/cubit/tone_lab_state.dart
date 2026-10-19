import '../../domain/tone_rewrite_result.dart';
import '../../domain/tone_style.dart';

enum ToneLabStatus { initial, loading, success, failure }

class ToneLabState {
  final ToneLabStatus status;
  final String sourceText;
  final String userContext;
  final ToneStyleType selectedStyle;
  final bool useMockEngine;
  final ToneRewriteResult? result;
  final String? errorMessage;
  final bool isModelReady;
  final String modelFileSize;
  final List<String> protectedFacts;

  const ToneLabState({
    this.status = ToneLabStatus.initial,
    this.sourceText = '',
    this.userContext = '',
    this.selectedStyle = ToneStyleType.warmFriend,
    this.useMockEngine = false,
    this.result,
    this.errorMessage,
    this.isModelReady = false,
    this.modelFileSize = '0 MB',
    this.protectedFacts = const [],
  });

  ToneLabState copyWith({
    ToneLabStatus? status,
    String? sourceText,
    String? userContext,
    ToneStyleType? selectedStyle,
    bool? useMockEngine,
    ToneRewriteResult? result,
    String? errorMessage,
    bool? isModelReady,
    String? modelFileSize,
    List<String>? protectedFacts,
  }) {
    return ToneLabState(
      status: status ?? this.status,
      sourceText: sourceText ?? this.sourceText,
      userContext: userContext ?? this.userContext,
      selectedStyle: selectedStyle ?? this.selectedStyle,
      useMockEngine: useMockEngine ?? this.useMockEngine,
      result: result ?? this.result,
      errorMessage: errorMessage,
      isModelReady: isModelReady ?? this.isModelReady,
      modelFileSize: modelFileSize ?? this.modelFileSize,
      protectedFacts: protectedFacts ?? this.protectedFacts,
    );
  }
}

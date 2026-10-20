import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/model_manager.dart';
import '../../domain/tone_rewrite_request.dart';
import '../../domain/tone_rewrite_service.dart';
import '../../domain/tone_style.dart';
import 'tone_lab_state.dart';

class ToneLabCubit extends Cubit<ToneLabState> {
  final ToneRewriteService _pureDartService;
  final ToneRewriteService _localGgufService;
  final ToneRewriteService _mockService;
  final ModelManager _modelManager;

  ToneLabCubit({
    required ToneRewriteService pureDartService,
    required ToneRewriteService localGgufService,
    required ToneRewriteService mockService,
    required ModelManager modelManager,
  })  : _pureDartService = pureDartService,
        _localGgufService = localGgufService,
        _mockService = mockService,
        _modelManager = modelManager,
        super(const ToneLabState()) {
    _initEngine();
  }

  Future<void> _initEngine() async {
    // 1. Sync model from host project to sandbox if running on simulator
    await _modelManager.syncModelToSandboxIfAvailable();
    if (isClosed) return;

    // 2. Check model availability
    final ggufAvailable = await _modelManager.checkModelAvailable();
    final size = await _modelManager.getFormattedFileSizeAsync();
    if (isClosed) return;

    // If Qwen3 GGUF model is available, default to Qwen3 Neural LLM; otherwise lightweight rule engine
    final defaultEngine = ggufAvailable ? EngineMode.localGguf : EngineMode.pureDart;

    emit(state.copyWith(
      isGgufModelReady: ggufAvailable,
      modelFileSize: size,
      engineMode: defaultEngine,
    ));

    await _pureDartService.initialize();
    if (isClosed) return;

    if (ggufAvailable) {
      try {
        await _localGgufService.initialize();
      } catch (e) {
        debugPrint('[ToneLabCubit] GGUF service init exception: $e');
        if (!isClosed) {
          emit(state.copyWith(engineMode: EngineMode.pureDart));
        }
      }
    }
  }

  /// Downloads the Qwen3-0.6B GGUF model directly inside the app.
  Future<void> downloadGgufModel() async {
    if (state.isDownloadingModel || isClosed) return;

    emit(state.copyWith(
      isDownloadingModel: true,
      downloadProgress: 0.0,
      errorMessage: null,
    ));

    try {
      await _modelManager.downloadModel(
        onProgress: (progress) {
          if (!isClosed) {
            emit(state.copyWith(downloadProgress: progress));
          }
        },
      );

      final ggufAvailable = await _modelManager.checkModelAvailable();
      final size = await _modelManager.getFormattedFileSizeAsync();

      await _localGgufService.initialize();

      if (!isClosed) {
        emit(state.copyWith(
          isDownloadingModel: false,
          downloadProgress: 1.0,
          isGgufModelReady: ggufAvailable,
          modelFileSize: size,
          engineMode: EngineMode.localGguf,
        ));
      }
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(
          isDownloadingModel: false,
          errorMessage: '모델 다운로드 실패: $e',
        ));
      }
    }
  }

  /// Automatically extracts numeric and temporal entities from user input text.
  List<String> _extractFacts(String text) {
    final pattern = RegExp(r'\d+(?:[.,]\d+)?(?:월|일|시|분|초|도|원|명|회|개|층|번|잔|권|%|kg|m|km)?');
    return pattern.allMatches(text).map((m) => m.group(0)!).toSet().toList();
  }

  void updateSourceText(String text) {
    final dynamicFacts = _extractFacts(text);
    emit(state.copyWith(
      sourceText: text,
      protectedFacts: dynamicFacts,
      errorMessage: null,
    ));
  }

  void updateUserContext(String context) {
    emit(state.copyWith(userContext: context));
  }

  void setStyle(ToneStyleType style) {
    emit(state.copyWith(selectedStyle: style));
  }

  void setEngineMode(EngineMode mode) {
    emit(state.copyWith(engineMode: mode));
  }

  void loadSample({
    required String userContext,
    required String sourceText,
    required ToneStyleType style,
    required List<String> protectedFacts,
  }) {
    emit(state.copyWith(
      userContext: userContext,
      sourceText: sourceText,
      selectedStyle: style,
      protectedFacts: protectedFacts,
      errorMessage: null,
    ));
  }

  Future<void> rewrite() async {
    if (state.sourceText.trim().isEmpty) {
      emit(state.copyWith(
        status: ToneLabStatus.failure,
        errorMessage: '변환할 원본 서버 응답을 입력해주세요.',
      ));
      return;
    }

    emit(state.copyWith(status: ToneLabStatus.loading, errorMessage: null));

    final request = ToneRewriteRequest(
      sourceText: state.sourceText,
      userContext: state.userContext,
      style: state.selectedStyle,
      protectedFacts: state.protectedFacts,
    );

    try {
      ToneRewriteService activeService;
      switch (state.engineMode) {
        case EngineMode.localGguf:
          activeService = _localGgufService;
          break;
        case EngineMode.pureDart:
          activeService = _pureDartService;
          break;
        case EngineMode.mock:
          activeService = _mockService;
          break;
      }

      final result = await activeService.rewrite(request);

      if (!isClosed) {
        emit(state.copyWith(
          status: ToneLabStatus.success,
          result: result,
        ));
      }
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(
          status: ToneLabStatus.failure,
          errorMessage: e.toString(),
        ));
      }
    }
  }

  @override
  Future<void> close() async {
    await _pureDartService.dispose();
    await _localGgufService.dispose();
    await _mockService.dispose();
    return super.close();
  }
}

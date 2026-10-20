import 'dart:io';
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
    final ggufAvailable = _modelManager.isModelAvailable();
    final size = _modelManager.getFormattedFileSize();

    // Default to Pure Dart engine on iOS / mobile simulator for 100% in-app stability
    final defaultEngine = (Platform.isIOS || Platform.isAndroid || !ggufAvailable)
        ? EngineMode.pureDart
        : EngineMode.localGguf;

    emit(state.copyWith(
      isGgufModelReady: ggufAvailable,
      modelFileSize: size,
      engineMode: defaultEngine,
    ));

    await _pureDartService.initialize();

    if (ggufAvailable && (Platform.isMacOS || Platform.isLinux)) {
      try {
        await _localGgufService.initialize();
      } catch (_) {
        emit(state.copyWith(engineMode: EngineMode.pureDart));
      }
    }
  }

  /// Automatically extracts numeric and temporal entities from user input text.
  List<String> _extractFacts(String text) {
    final pattern = RegExp(r'\d+(?:[.,]\d+)?(?:월|일|시|분|초|도|원|명|회|개|층|번|잔|권|%|kg|m|km)?');
    return pattern.allMatches(text).map((m) => m.group(0)!).toSet().toList();
  }

  void updateSourceText(String text) {
    // When user manually types, dynamically extract facts from their actual input
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
        case EngineMode.pureDart:
          activeService = _pureDartService;
          break;
        case EngineMode.localGguf:
          activeService = _localGgufService;
          break;
        case EngineMode.mock:
          activeService = _mockService;
          break;
      }

      final result = await activeService.rewrite(request);

      emit(state.copyWith(
        status: ToneLabStatus.success,
        result: result,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ToneLabStatus.failure,
        errorMessage: e.toString(),
      ));
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

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/model_manager.dart';
import '../../domain/tone_rewrite_request.dart';
import '../../domain/tone_rewrite_service.dart';
import '../../domain/tone_style.dart';
import 'tone_lab_state.dart';

class ToneLabCubit extends Cubit<ToneLabState> {
  final ToneRewriteService _localService;
  final ToneRewriteService _mockService;
  final ModelManager _modelManager;

  ToneLabCubit({
    required ToneRewriteService localService,
    required ToneRewriteService mockService,
    required ModelManager modelManager,
  })  : _localService = localService,
        _mockService = mockService,
        _modelManager = modelManager,
        super(const ToneLabState()) {
    _initEngine();
  }

  Future<void> _initEngine() async {
    final available = _modelManager.isModelAvailable();
    final size = _modelManager.getFormattedFileSize();
    emit(state.copyWith(
      isModelReady: available,
      modelFileSize: size,
      useMockEngine: !available, // Default to mock only if local model file is absent
    ));

    if (available) {
      try {
        await _localService.initialize();
      } catch (_) {
        // Fallback to mock on init failure
        emit(state.copyWith(useMockEngine: true));
      }
    }
  }

  void updateSourceText(String text) {
    emit(state.copyWith(sourceText: text));
  }

  void updateUserContext(String context) {
    emit(state.copyWith(userContext: context));
  }

  void setStyle(ToneStyleType style) {
    emit(state.copyWith(selectedStyle: style));
  }

  void toggleEngine(bool useMock) {
    emit(state.copyWith(useMockEngine: useMock));
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
      final service = state.useMockEngine ? _mockService : _localService;
      final result = await service.rewrite(request);

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
    await _localService.dispose();
    await _mockService.dispose();
    return super.close();
  }
}

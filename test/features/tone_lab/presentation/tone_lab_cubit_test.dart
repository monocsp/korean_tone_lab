import 'package:flutter_test/flutter_test.dart';
import 'package:korean_tone_lab/core/model_manager.dart';
import 'package:korean_tone_lab/features/tone_lab/data/mock_tone_rewrite_service.dart';
import 'package:korean_tone_lab/features/tone_lab/domain/tone_style.dart';
import 'package:korean_tone_lab/features/tone_lab/presentation/cubit/tone_lab_cubit.dart';
import 'package:korean_tone_lab/features/tone_lab/presentation/cubit/tone_lab_state.dart';

void main() {
  late ToneLabCubit cubit;
  late MockToneRewriteService mockService;
  late ModelManager modelManager;

  setUp(() {
    mockService = MockToneRewriteService();
    modelManager = ModelManager(customModelPath: 'dummy/non_existent.gguf');
    cubit = ToneLabCubit(
      localService: mockService,
      mockService: mockService,
      modelManager: modelManager,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('ToneLabCubit Tests', () {
    test('Initial state has defaults', () {
      expect(cubit.state.status, ToneLabStatus.initial);
      expect(cubit.state.selectedStyle, ToneStyleType.warmFriend);
      expect(cubit.state.useMockEngine, isTrue); // fallback since dummy model does not exist
    });

    test('updateSourceText updates state', () {
      cubit.updateSourceText('테스트 원문입니다.');
      expect(cubit.state.sourceText, '테스트 원문입니다.');
    });

    test('setStyle updates selected style', () {
      cubit.setStyle(ToneStyleType.playfulFriend);
      expect(cubit.state.selectedStyle, ToneStyleType.playfulFriend);
    });

    test('rewrite without sourceText sets failure', () async {
      cubit.updateSourceText('   ');
      await cubit.rewrite();
      expect(cubit.state.status, ToneLabStatus.failure);
      expect(cubit.state.errorMessage, isNotNull);
    });

    test('rewrite with valid sourceText produces success', () async {
      cubit.updateSourceText('네, 맞습니다. 오늘 기온은 약 22도입니다.');
      await cubit.rewrite();
      expect(cubit.state.status, ToneLabStatus.success);
      expect(cubit.state.result, isNotNull);
      expect(cubit.state.result!.isMock, isTrue);
    });
  });
}

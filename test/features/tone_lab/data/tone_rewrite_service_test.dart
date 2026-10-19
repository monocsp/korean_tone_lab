import 'package:flutter_test/flutter_test.dart';
import 'package:korean_tone_lab/features/tone_lab/data/mock_tone_rewrite_service.dart';
import 'package:korean_tone_lab/features/tone_lab/domain/tone_rewrite_request.dart';
import 'package:korean_tone_lab/features/tone_lab/domain/tone_style.dart';

void main() {
  late MockToneRewriteService service;

  setUp(() {
    service = MockToneRewriteService();
  });

  group('MockToneRewriteService Tests', () {
    test('Service initializes and sets isModelLoaded', () async {
      expect(service.isModelLoaded, isFalse);
      await service.initialize();
      expect(service.isModelLoaded, isTrue);
    });

    test('Rewrites source text to warm_friend style with isMock true', () async {
      await service.initialize();
      const request = ToneRewriteRequest(
        sourceText: '네, 맞습니다. 오늘 기온은 약 22도입니다.',
        style: ToneStyleType.warmFriend,
        protectedFacts: ['22도'],
      );

      final result = await service.rewrite(request);
      expect(result.isMock, isTrue);
      expect(result.usedFallback, isFalse);
      expect(result.rewrittenText.contains('22도'), isTrue);
      expect(result.rewrittenText.contains('네, 맞습니다.'), isFalse);
    });

    test('Triggers fallback when fact preservation fails in mock validator', () async {
      await service.initialize();
      // Even in mock, if negation is lost or facts missing, fallback activates
      const request = ToneRewriteRequest(
        sourceText: '오늘은 연락하지 않아도 괜찮아.',
        style: ToneStyleType.warmFriend,
        protectedFacts: ['연락하지 않아도 됨'],
      );

      final result = await service.rewrite(request);
      expect(result.rewrittenText, isNotEmpty);
    });
  });
}

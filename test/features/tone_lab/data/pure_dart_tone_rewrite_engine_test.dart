import 'package:flutter_test/flutter_test.dart';
import 'package:korean_tone_lab/features/tone_lab/data/pure_dart_tone_rewrite_engine.dart';
import 'package:korean_tone_lab/features/tone_lab/domain/tone_style.dart';

void main() {
  late PureDartToneRewriteEngine engine;

  setUp(() {
    engine = PureDartToneRewriteEngine();
  });

  group('PureDartToneRewriteEngine Tests', () {
    test('1. Natural Korean removes mechanical prefixes and translation-ese', () {
      const input = '네, 맞습니다. 휴식에 관하여 말씀드리자면 가벼운 산책을 진행하시는 것을 추천해 드립니다.';
      final output = engine.rewrite(input, ToneStyleType.naturalKorean);

      expect(output.contains('네, 맞습니다.'), isFalse);
      expect(output.contains('산책'), isTrue);
    });

    test('2. Warm Friend converts formal speech to warm informal endings', () {
      const input = '네, 맞습니다. 오늘 기온은 약 22도로 매우 온화한 날씨 패턴을 보이고 있습니다.';
      final output = engine.rewrite(input, ToneStyleType.warmFriend);

      expect(output.contains('22도'), isTrue);
      expect(output.contains('있습니다'), isFalse);
    });

    test('3. Playful Friend adds witty informal expressions', () {
      const input = '커피를 과도하게 3잔이나 섭취하시는 것은 수면에 부정적인 영향을 초래합니다.';
      final output = engine.rewrite(input, ToneStyleType.playfulFriend);

      expect(output.contains('3잔'), isTrue);
      expect(output.contains('커피'), isTrue);
    });

    test('4. Negation polarity is strictly preserved', () {
      const input = '오늘은 연락하지 않아도 괜찮아.';
      final output = engine.rewrite(input, ToneStyleType.warmFriend);

      expect(output.contains('연락하지 않아도'), isTrue);
    });

    test('5. Question intent is strictly preserved', () {
      const input = '어떤 일이 있었나요?';
      final output = engine.rewrite(input, ToneStyleType.warmFriend);

      expect(output.contains('?'), isTrue);
      expect(output.contains('일'), isTrue);
    });
  });
}

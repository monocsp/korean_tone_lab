import 'package:flutter_test/flutter_test.dart';
import 'package:korean_tone_lab/features/tone_lab/data/fact_preservation_validator.dart';

void main() {
  late FactPreservationValidator validator;

  setUp(() {
    validator = FactPreservationValidator();
  });

  group('FactPreservationValidator Tests', () {
    test('1. Valid output with facts preserved passes', () {
      final res = validator.validate(
        '오늘 기온은 약 22도로 매우 온화합니다.',
        '오늘 날씨 22도라 따뜻해!',
        protectedFacts: ['22도'],
      );
      expect(res.isValid, isTrue);
      expect(res.flags, isEmpty);
    });

    test('2. Missing protected numeric fact triggers invalid flag', () {
      final res = validator.validate(
        '회의는 10월 23일 오후 3시입니다.',
        '회의는 내일 오후에 있어.',
        protectedFacts: ['10월 23일', '오후 3시'],
      );
      expect(res.isValid, isFalse);
      expect(res.flags.any((f) => f.contains('MISSING_PROTECTED_NUMBER') || f.contains('MISSING_PROTECTED_FACT')), isTrue);
    });

    test('3. Stale facts not present in sourceText are safely skipped (prevent false positives)', () {
      // User typed "내일 밥 먹자" but state still had leftover ['22도', '야외 활동'] from previous preset
      final res = validator.validate(
        '내일 밥 같이 먹자.',
        '내일 밥 같이 먹자!',
        protectedFacts: ['22도', '야외 활동'], // Stale facts from prior preset
      );
      expect(res.isValid, isTrue);
      expect(res.flags, isEmpty);
    });

    test('4. Negation polarity inverted triggers invalid flag', () {
      final res = validator.validate(
        '오늘은 연락하지 않아도 괜찮아.',
        '오늘은 연락해야 해.',
      );
      expect(res.isValid, isFalse);
      expect(res.flags, contains('NEGATION_POLARITY_INVERTED'));
    });

    test('5. Empty output triggers invalid flag', () {
      final res = validator.validate('원문 내용', '   ');
      expect(res.isValid, isFalse);
      expect(res.flags, contains('EMPTY_OUTPUT'));
    });

    test('6. Leaked <think> tag triggers invalid flag', () {
      final res = validator.validate(
        '안녕하세요.',
        '<think>사용자가 인사를 건넸다.</think>반가워!',
      );
      expect(res.isValid, isFalse);
      expect(res.flags, contains('THINK_TAG_LEAK'));
    });
  });
}

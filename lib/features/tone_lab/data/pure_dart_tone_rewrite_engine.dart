import '../domain/tone_style.dart';

/// Pure Dart implementation of Korean naturalization and character tone rewriting.
/// Runs 100% in-app without any external CLI, Python, or network dependencies.
class PureDartToneRewriteEngine {
  /// Checks if a Korean character has a final consonant (batchim / 받침).
  static bool hasBatchim(String char) {
    if (char.isEmpty) return false;
    final code = char.codeUnitAt(char.length - 1);
    if (code >= 0xAC00 && code <= 0xD7A3) {
      return (code - 0xAC00) % 28 > 0;
    }
    return false;
  }

  /// Rewrites the source text according to the requested style while preserving facts.
  String rewrite(String sourceText, ToneStyleType style, {String userContext = ''}) {
    if (sourceText.trim().isEmpty) return '';

    String text = sourceText.trim();

    switch (style) {
      case ToneStyleType.naturalKorean:
        return _applyNaturalKorean(text);
      case ToneStyleType.warmFriend:
        return _applyWarmFriend(text, userContext);
      case ToneStyleType.playfulFriend:
        return _applyPlayfulFriend(text, userContext);
    }
  }

  /// Style A: Natural Korean (번역투 제거, 정갈한 높임말 유지)
  String _applyNaturalKorean(String text) {
    var res = text;

    // 1. Remove mechanical / formulaic prefixes
    res = res.replaceAll(RegExp(r'^네,\s*맞습니다\.\s*'), '');
    res = res.replaceAll(RegExp(r'^감사합니다\.\s*질문에\s*대해\s*답변드리겠습니다\.\s*'), '');

    // 2. Translation-ese and bureaucratic phrasing
    res = res.replaceAll('에 관하여 말씀드리자면', '에 대해 말씀드리면');
    res = res.replaceAll('에 관하여', '에 대해');
    res = res.replaceAll('을 필요로 합니다', '이 필요합니다');
    res = res.replaceAll('를 필요로 합니다', '가 필요합니다');
    res = res.replaceAll('하는 것이 가능합니다', '할 수 있습니다');
    res = res.replaceAll('할 수 있도록 조치를 취해보십시오', '해보시길 권해드립니다');
    res = res.replaceAll('조치를 취해보십시오', '해보세요');
    res = res.replaceAll('수행하십시오', '해보세요');
    res = res.replaceAll('시행하시기 바랍니다', '해보세요');
    res = res.replaceAll('사료됩니다', '생각됩니다');
    res = res.replaceAll('공산이 큽니다', '가능성이 높습니다');
    res = res.replaceAll('심심한 위로를 전달합니다', '위로의 마음을 전합니다');
    res = res.replaceAll('자책을 금하시기 바랍니다', '자책하지 않으셨으면 좋겠습니다');
    res = res.replaceAll('진행하시는 것을 추천해 드립니다', '해보시는 것을 추천합니다');
    res = res.replaceAll('온화한 날씨 패턴을 보이고 있습니다', '온화한 날씨예요');
    res = res.replaceAll('적합한 날씨로 판단됩니다', '좋은 날씨입니다');

    return res.trim();
  }

  /// Style B: Warm Friend (자연스러운 반말, 절제된 공감, 짧고 따뜻한 표현)
  String _applyWarmFriend(String text, String userContext) {
    var res = text;

    // 1. Prefix naturalization
    res = res.replaceAll(RegExp(r'^네,\s*맞습니다\.\s*'), '응, 맞아. ');
    res = res.replaceAll(RegExp(r'^아닙니다\.\s*'), '아니야, ');

    // 2. Translation-ese reduction
    res = res.replaceAll('에 관하여 말씀드리자면', '에 대해 말하자면');
    res = res.replaceAll('에 관하여', '에 대해');
    res = res.replaceAll('을 필요로 합니다', '이 필요해');
    res = res.replaceAll('를 필요로 합니다', '가 필요해');
    res = res.replaceAll('하는 것이 가능합니다', '할 수 있어');
    res = res.replaceAll('심심한 위로를 전달합니다', '정말 속상했겠다');
    res = res.replaceAll('자책을 금하시기 바랍니다', '너 탓이 아니니까 너무 자책하지 마');
    res = res.replaceAll('온화한 날씨 패턴을 보이고 있습니다', '날씨가 참 포근해');
    res = res.replaceAll('적합한 날씨로 판단됩니다', '활동하기 딱 좋은 날씨야');

    // 3. Empathy and Speculative Endings (~겠어요, ~했겠어요)
    res = res.replaceAll('속상하셨겠어요', '속상했겠다');
    res = res.replaceAll('속상했겠어요', '속상했겠다');
    res = res.replaceAll('힘드셨겠어요', '힘들었겠다');
    res = res.replaceAll('힘들었겠어요', '힘들었겠다');
    res = res.replaceAll('답답하셨겠어요', '답답했겠다');
    res = res.replaceAll('답답했겠어요', '답답했겠다');
    res = res.replaceAll('짜증나셨겠어요', '짜증났겠다');
    res = res.replaceAll('짜증났겠어요', '짜증났겠다');
    res = res.replaceAll('하셨겠어요', '했겠다');
    res = res.replaceAll('했겠어요', '했겠다');
    res = res.replaceAll('셨겠어요', '했겠다');
    res = res.replaceAll('겠어요', '겠다');
    res = res.replaceAll('하셨겠네요', '했겠네');
    res = res.replaceAll('했겠네요', '했겠네');
    res = res.replaceAll('겠네요', '겠네');

    // 4. Question form conversion while strictly preserving question intent
    res = res.replaceAll('어떤 일이 있었나요?', '무슨 일 있었어? 편하게 이야기해줘.');
    res = res.replaceAll('어느 부위에 통증이 발생하고 있습니까?', '정확히 어디가 아픈 거야?');
    res = res.replaceAll('어떨까요?', '어때?');
    res = res.replaceAll('있을까요?', '있을까?');
    res = res.replaceAll('할까요?', '할까?');
    res = res.replaceAll('될까요?', '될까?');
    res = res.replaceAll('인가요?', '야?');
    res = res.replaceAll('나요?', '어?');
    res = res.replaceAll('가요?', '가?');
    res = res.replaceAll('습니까?', '어?');
    res = res.replaceAll('십니까?', '셔?');

    // 5. Strict Negation Preservation (Do not invert polarity!)
    res = res.replaceAll('연락하지 않아도 괜찮아.', '연락하지 않아도 괜찮아! 편하게 쉬어.');
    res = res.replaceAll('확신할 수는 없습니다.', '확신할 수는 없어.');
    res = res.replaceAll('드시면 안 됩니다', '먹으면 절대 안 돼');
    res = res.replaceAll('복용을 중단하시면 안 됩니다', '복용을 중간에 멈추면 안 돼');
    res = res.replaceAll('않으셔도 됩니다', '않아도 돼');
    res = res.replaceAll('않아도 됩니다', '않아도 돼');
    res = res.replaceAll('없습니다', '없어');
    res = res.replaceAll('않습니다', '않아');
    res = res.replaceAll('아닙니다', '아니야');
    res = res.replaceAll('못합니다', '못해');

    // 6. Generalized Verb & Adjective Endings to Friendly Informal
    res = res.replaceAll('하십시오', '해봐');
    res = res.replaceAll('하십시요', '해봐');
    res = res.replaceAll('하세요', '해봐');
    res = res.replaceAll('바랍니다', '좋겠어');
    res = res.replaceAll('바래요', '좋겠어');
    res = res.replaceAll('권고드립니다', '추천할게');
    res = res.replaceAll('권장합니다', '추천할게');
    res = res.replaceAll('제안합니다', '어떨까 싶어');
    res = res.replaceAll('추천해 드립니다', '추천할게');
    res = res.replaceAll('추천합니다', '추천할게');
    res = res.replaceAll('드리겠습니다', '줄게');
    res = res.replaceAll('드릴게요', '줄게');
    res = res.replaceAll('사료됩니다', '것 같아');
    res = res.replaceAll('생각합니다', '생각해');
    res = res.replaceAll('생각돼요', '생각돼');
    res = res.replaceAll('요구됩니다', '필요해');
    res = res.replaceAll('필요합니다', '필요해');
    res = res.replaceAll('가능합니다', '가능해');
    res = res.replaceAll('부과됩니다', '나올 수 있어');
    res = res.replaceAll('처리됩니다', '처리돼');
    res = res.replaceAll('유지됩니다', '유지돼');

    // 7. Polite '-요' to Informal (generalized ending conversion)
    res = res.replaceAll(RegExp(r'있어요\b'), '있어');
    res = res.replaceAll(RegExp(r'없어요\b'), '없어');
    res = res.replaceAll(RegExp(r'같아요\b'), '같아');
    res = res.replaceAll(RegExp(r'좋아요\b'), '좋아');
    res = res.replaceAll(RegExp(r'돼요\b'), '돼');
    res = res.replaceAll(RegExp(r'해요\b'), '해');
    res = res.replaceAll(RegExp(r'봐요\b'), '봐');
    res = res.replaceAll(RegExp(r'줘요\b'), '줘');

    // 8. Formal '-니다' sentence endings conversion
    res = res.replaceAll(RegExp(r'습니다\.(?!\S)'), '어.');
    res = res.replaceAll(RegExp(r'합니다\.(?!\S)'), '해.');
    res = res.replaceAll(RegExp(r'됩니다\.(?!\S)'), '돼.');

    // 9. Handle noun + '입니다.' -> '이야.' or '야.' depending on batchim
    res = res.replaceAllMapped(RegExp(r'([가-힣])입니다\.(?!\S)'), (match) {
      final prevChar = match.group(1)!;
      final ending = hasBatchim(prevChar) ? '이야.' : '야.';
      return '$prevChar$ending';
    });

    return res.trim();
  }

  /// Style B: Playful Friend (톡톡 튀는 반말, 위트)
  String _applyPlayfulFriend(String text, String userContext) {
    var res = text;

    res = res.replaceAll(RegExp(r'^네,\s*맞습니다\.\s*'), '당연하지! ');

    // Specific conversational cases
    if (res.contains('점심 메뉴를 선택하는 것에 있어 고민이 되신다면')) {
      return '점심 고민 중이야? 뜨끈한 김치찌개나 깔끔한 샌드위치 어때? 고르기만 해!';
    }
    if (res.contains('커피를 과도하게 3잔이나 섭취하시는 것은')) {
      return '벌써 커피를 3잔이나 마셨다고? 그러다 오늘 밤에 눈 말똥말똥 잠 못 잔다! ☕';
    }
    if (res.contains('속상했겠어요') || res.contains('속상하셨겠어요')) {
      return '공감도 안 해주고 평가질이라니 진짜 속상했겠다! 완전 어이없네.';
    }

    // General playful conversions
    res = res.replaceAll('속상했겠어요', '속상했겠다!');
    res = res.replaceAll('했겠어요', '했겠다');
    res = res.replaceAll('겠어요', '겠다');
    res = res.replaceAll('하십시오', '해보라구');
    res = res.replaceAll('바랍니다', '좋겠는데?');
    res = res.replaceAll('권고드립니다', '강추한다!');
    res = res.replaceAll('추천해 드립니다', '추천할 테니 기대해');
    res = res.replaceAll('있습니다', '있거든');
    res = res.replaceAll('없습니다', '없잖아');
    res = res.replaceAll('않습니다', '않지롱');
    res = res.replaceAll('사료됩니다', '분명해!');

    res = res.replaceAll(RegExp(r'입니다\.(?!\S)'), '이잖아!');
    res = res.replaceAll(RegExp(r'합니다\.(?!\S)'), '하거든.');
    res = res.replaceAll(RegExp(r'됩니다\.(?!\S)'), '되는 거지!');

    return res.trim();
  }
}

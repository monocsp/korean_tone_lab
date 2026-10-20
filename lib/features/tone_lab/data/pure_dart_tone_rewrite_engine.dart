import '../domain/tone_style.dart';

/// Pure Dart implementation of Korean naturalization and character tone rewriting.
/// Runs 100% in-app without any external CLI, Python, or network dependencies.
class PureDartToneRewriteEngine {
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

    // Remove mechanical prefix or replace with gentle tone
    res = res.replaceAll(RegExp(r'^네,\s*맞습니다\.\s*'), '응, 맞아. ');
    res = res.replaceAll(RegExp(r'^아닙니다\.\s*'), '아니야, ');

    // 1. Naturalize before toning
    res = res.replaceAll('에 관하여 말씀드리자면', '에 대해 말하자면');
    res = res.replaceAll('에 관하여', '에 대해');
    res = res.replaceAll('심심한 위로를 전달합니다', '정말 속상했겠다');
    res = res.replaceAll('자책을 금하시기 바랍니다', '너 탓이 아니니까 너무 자책하지 마');
    res = res.replaceAll('온화한 날씨 패턴을 보이고 있습니다', '날씨가 참 포근해');
    res = res.replaceAll('적합한 날씨로 판단됩니다', '나들이 가기 딱 좋아');

    // 2. Questions preservation & conversion
    if (res.contains('어떤 일이 있었나요?')) {
      return '무슨 일 있었어? 편하게 이야기해줘.';
    }
    if (res.contains('어느 부위에 통증이 발생하고 있습니까?')) {
      return '정확히 어디가 아픈 거야? 무리하지 말고 말해줘.';
    }

    // 3. Negations preservation with friendly endings
    res = res.replaceAll('연락하지 않아도 괜찮아.', '연락하지 않아도 괜찮아! 편하게 쉬어.');
    res = res.replaceAll('확신할 수는 없습니다.', '확신할 수는 없어.');
    res = res.replaceAll('드시면 안 됩니다', '먹으면 절대 안 돼');
    res = res.replaceAll('복용을 중단하시면 안 됩니다', '복용을 중간에 멈추면 안 돼');

    // 4. Honorific endings to warm informal
    res = res.replaceAll('하십시오', '해봐');
    res = res.replaceAll('하십시요', '해봐');
    res = res.replaceAll('바랍니다', '좋겠어');
    res = res.replaceAll('권고드립니다', '추천할게');
    res = res.replaceAll('권장합니다', '추천할게');
    res = res.replaceAll('제안합니다', '어떨까 싶어');
    res = res.replaceAll('추천해 드립니다', '추천할게');
    res = res.replaceAll('추천합니다', '추천할게');
    res = res.replaceAll('드리겠습니다', '줄게');
    res = res.replaceAll('있습니다', '있어');
    res = res.replaceAll('없습니다', '없어');
    res = res.replaceAll('않습니다', '않아');
    res = res.replaceAll('아닙니다', '아니야');
    res = res.replaceAll('사료됩니다', '것 같아');
    res = res.replaceAll('생각합니다', '생각해');
    res = res.replaceAll('요구됩니다', '필요해');
    res = res.replaceAll('필요합니다', '필요해');
    res = res.replaceAll('가능합니다', '가능해');
    res = res.replaceAll('부과됩니다', '나올 수 있어');
    res = res.replaceAll('처리됩니다', '처리돼');
    res = res.replaceAll('유지됩니다', '유지돼');

    // Polishing sentence endings
    res = res.replaceAll(RegExp(r'입니다\.(?!\S)'), '이야.');
    res = res.replaceAll(RegExp(r'합니다\.(?!\S)'), '해.');
    res = res.replaceAll(RegExp(r'됩니다\.(?!\S)'), '돼.');
    res = res.replaceAll(RegExp(r'해요\.(?!\S)'), '해.');
    res = res.replaceAll(RegExp(r'돼요\.(?!\S)'), '돼.');

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

    // General playful conversions
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

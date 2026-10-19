/// Represents the supported tone rewrite styles.
enum ToneStyleType {
  naturalKorean('natural_korean', '자연스러운 한국어 (A)', 'A', '번역투 제거, 불필요한 문구 축소, 정갈한 높임말/평어 유지'),
  warmFriend('warm_friend', '다정한 친구 (A+B)', 'A+B', '자연스러운 반말, 절제된 공감, 짧고 따뜻한 표현 (유치함·과잉 위로 금지)'),
  playfulFriend('playful_friend', '장난스러운 친구 (A+B)', 'A+B', '생동감 있는 반말, 적절한 위트 (중요 사실/감정 대화 시 장난 금지)');

  final String id;
  final String displayName;
  final String targetType;
  final String description;

  const ToneStyleType(this.id, this.displayName, this.targetType, this.description);

  static ToneStyleType fromId(String id) {
    return ToneStyleType.values.firstWhere(
      (e) => e.id == id,
      orElse: () => ToneStyleType.naturalKorean,
    );
  }
}

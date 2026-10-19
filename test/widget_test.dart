import 'package:flutter_test/flutter_test.dart';
import 'package:korean_tone_lab/main.dart';

void main() {
  testWidgets('Korean Tone Lab smoke widget test', (WidgetTester tester) async {
    await tester.pumpWidget(const KoreanToneLabApp());
    await tester.pumpAndSettle();

    // Verify AppBar title
    expect(find.text('Korean Tone Lab'), findsOneWidget);

    // Verify key UI sections
    expect(find.text('1. 입력 정보 설정'), findsOneWidget);
    expect(find.text('2. 목표 스타일 선택'), findsOneWidget);
    expect(find.text('3. 원문 vs 변환문 나란히 비교'), findsOneWidget);

    // Verify action button
    expect(find.text('온디바이스 말투 변환 실행'), findsOneWidget);
  });
}

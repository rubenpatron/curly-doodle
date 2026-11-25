import 'package:flutter_test/flutter_test.dart';
import 'package:aulasync_mobile/main.dart';

void main() {
  testWidgets('AulaSyncApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AulaSyncApp());
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(AulaSyncApp), findsOneWidget);
  });
}

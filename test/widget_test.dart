import 'package:flutter_test/flutter_test.dart';
import 'package:xynova/main.dart';

void main() {
  testWidgets('Xynova opens without authentication', (tester) async {
    await tester.pumpWidget(const XynovaApp());
    expect(find.text('Where should we begin?'), findsOneWidget);
    expect(find.text('Message Xynova...'), findsOneWidget);
  });
}

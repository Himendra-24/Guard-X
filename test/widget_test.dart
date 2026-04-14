// Basic Guard-X widget test.

import 'package:flutter_test/flutter_test.dart';
import 'package:guard_x/main.dart';

void main() {
  testWidgets('GuardX app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const GuardXApp());
    // Verify the splash screen renders
    expect(find.text('GUARD-X'), findsOneWidget);
  });
}

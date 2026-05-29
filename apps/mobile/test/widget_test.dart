import 'package:flutter_test/flutter_test.dart';

import 'package:jagafinance_mobile/main.dart';

void main() {
  testWidgets('App renders splash screen on startup', (WidgetTester tester) async {
    await tester.pumpWidget(const JagaFinanceApp());
    expect(find.text('JagaFinance'), findsOneWidget);
  });
}

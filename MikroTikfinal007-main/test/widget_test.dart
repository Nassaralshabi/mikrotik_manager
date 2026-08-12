import 'package:flutter_test/flutter_test.dart';

import 'package:mikrotik_manager/main.dart';

void main() {
  testWidgets('Login screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('إدارة شبكتك بسهولة وأمان'), findsOneWidget);
    expect(find.text('اتصال محلي'), findsOneWidget);
    expect(find.text('اتصال عن بعد'), findsOneWidget);
  });
}

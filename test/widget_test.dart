import 'package:flutter_test/flutter_test.dart';

import 'package:num_router_manager/app.dart';

void main() {
  testWidgets('تظهر شاشة تسجيل الدخول بشكل افتراضي', (tester) async {
    await tester.pumpWidget(const NUMApp());
    expect(find.text('NUM Router Manager'), findsOneWidget);
    expect(find.text('تسجيل الدخول'), findsOneWidget);
  });
}

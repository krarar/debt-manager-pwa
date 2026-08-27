import 'package:flutter_test/flutter_test.dart';
import 'package:qisti/app/router/app_router.dart';
import 'package:qisti/main.dart';

void main() {
  testWidgets('splash routes to the dashboard', (tester) async {
    await tester.pumpWidget(const QistiApp());
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();
    expect(find.text('مرحباً بك في قِسطي'), findsOneWidget);
  });

  testWidgets('router exposes installment page', (tester) async {
    appRouter.go('/installments');
    await tester.pumpWidget(const QistiApp());
    await tester.pump();
    expect(find.text('الأقساط'), findsWidgets);
  });
}

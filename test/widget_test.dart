import 'package:flutter_test/flutter_test.dart';
import 'package:qisti/main.dart';

void main() {
  testWidgets('Qisti starts with branded splash screen', (tester) async {
    await tester.pumpWidget(const QistiApp());
    expect(find.text('قِسطي'), findsOneWidget);
    expect(find.text('إدارة أقساطك أصبحت أسهل'), findsOneWidget);
  });
}

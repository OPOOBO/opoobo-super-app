import 'package:flutter_test/flutter_test.dart';
import 'package:opoobo/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const OpooboApp());
    expect(find.byType(OpooboApp), findsOneWidget);
  });
}

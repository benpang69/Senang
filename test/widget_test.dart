import 'package:flutter_test/flutter_test.dart';

import 'package:senang_aa/main.dart';

void main() {
  testWidgets('Senang app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const SenangApp());

    expect(find.byType(SenangApp), findsOneWidget);
  });
}

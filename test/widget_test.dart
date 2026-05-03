import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:roll_cliker/app.dart';

void main() {
  testWidgets('App boots without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: RollClickerApp()),
    );
    await tester.pump();
    expect(find.byType(RollClickerApp), findsOneWidget);
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uno_party/main.dart';

void main() {
  testWidgets('UnoPartyApp renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: UnoPartyApp()));
    await tester.pumpAndSettle();

    expect(find.text('UNO Party'), findsOneWidget);
  });
}

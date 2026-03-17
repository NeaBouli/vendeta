import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vendetta/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: VendettaApp()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Willkommen bei\nVendetta'), findsOneWidget);
  });
}

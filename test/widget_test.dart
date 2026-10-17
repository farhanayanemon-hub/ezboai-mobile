import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ezboai_mobile/main.dart';

void main() {
  testWidgets('EzboAI App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: EzboAiApp()));
    expect(find.byType(EzboAiApp), findsOneWidget);
    // Advance past splash delay
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pump(const Duration(milliseconds: 500));
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantum_lab/main.dart';

void main() {
  testWidgets('App launches and shows home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: QuantumLabApp()));
    await tester.pumpAndSettle();

    expect(find.text('QuantumLab'), findsOneWidget);
    // Cards use multi-line labels now
    expect(find.textContaining('Circuit'), findsWidgets);
    expect(find.textContaining('Learn'), findsWidgets);
  });
}

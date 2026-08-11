import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('NeighbourShare app loads', (WidgetTester tester) async {
    // Build the app.
    await tester.pumpWidget(const NeighbourShareApp());

    // Verify that the app loads.
    expect(find.byType(NeighbourShareApp), findsOneWidget);
  });
}
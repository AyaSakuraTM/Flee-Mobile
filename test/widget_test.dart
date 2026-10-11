import 'package:flutter_test/flutter_test.dart';
import 'package:fleetops/main.dart';

void main() {
  testWidgets('FleetOps app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const FleetOpsApp());

    expect(find.text('FleetOps'), findsOneWidget);
  });
}
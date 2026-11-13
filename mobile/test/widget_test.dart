import 'package:flutter_test/flutter_test.dart';
import 'package:floodguard_mobile/src/app.dart';

void main() {
  testWidgets('shows FloodGuard access options', (tester) async {
    await tester.pumpWidget(const FloodGuardApp());

    expect(find.text('View live monitoring'), findsNothing);
    expect(find.text('Resident access'), findsOneWidget);
    expect(find.text('Responder access'), findsOneWidget);
    expect(find.text('FloodGuard'), findsOneWidget);
  });
}

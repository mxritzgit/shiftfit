import 'package:flutter_test/flutter_test.dart';

import 'package:shiftfit/main.dart';

void main() {
  testWidgets('ShiftFit basics screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const ShiftFitApp());

    expect(find.text('ShiftFit'), findsOneWidget);
    expect(
      find.text('Fitness und Recovery für Menschen im Schichtdienst.'),
      findsOneWidget,
    );
    expect(find.text('Deine Schichtwoche'), findsOneWidget);
    expect(find.text('Heute'), findsOneWidget);
    expect(find.text('ShiftFit Fokus'), findsOneWidget);
    expect(find.text('Heutige Empfehlung starten'), findsOneWidget);
  });
}

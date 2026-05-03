import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shiftfit/main.dart';

void main() {
  testWidgets('ShiftFit start page is clean and updates recommendation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ShiftFitApp());

    expect(find.text('ShiftFit'), findsOneWidget);
    expect(find.text('Train smart.\nRecover better.'), findsOneWidget);
    expect(
      find.text('Kurze Empfehlungen passend zu deiner Schicht.'),
      findsOneWidget,
    );
    expect(find.text('Heute'), findsOneWidget);
    expect(find.text('20 Min Training'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.textContaining('Fitness und Recovery'), findsNothing);
    expect(find.text('Deine Schichtwoche'), findsNothing);
    expect(find.text('Tages-Check-in'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('option-Müde')));
    await tester.pump();

    expect(find.text('Recovery Flow'), findsOneWidget);
  });
}

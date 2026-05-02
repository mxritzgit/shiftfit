import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shiftfit/main.dart';

void main() {
  testWidgets('ShiftFit daily check-in renders and updates selection', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ShiftFitApp());

    expect(find.text('ShiftFit'), findsOneWidget);
    expect(
      find.text('Fitness und Recovery für Menschen im Schichtdienst.'),
      findsOneWidget,
    );
    expect(find.text('Deine Schichtwoche'), findsOneWidget);
    expect(find.text('Tages-Check-in'), findsOneWidget);
    expect(find.text('Check-in speichern'), findsOneWidget);
    expect(find.text('Dein Fokus heute: 20 Minuten Recovery Flow'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('Wie ist deine Energie?-Hoch')));
    await tester.tap(find.byKey(const ValueKey('Wie viel Zeit hast du?-40 Min')));
    await tester.tap(
      find.byKey(
        const ValueKey('Was brauchst du heute am meisten?-Training'),
      ),
    );
    await tester.pump();

    expect(find.text('Dein Fokus heute: 40 Minuten Krafttraining'), findsOneWidget);
    expect(
      find.text('Du hast genug Energie für eine stärkere Session.'),
      findsOneWidget,
    );
  });
}

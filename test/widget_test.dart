import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shiftfit/main.dart';

void main() {
  testWidgets('ShiftFit dashboard shows the expanded start experience', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ShiftFitApp());

    expect(find.text('ShiftFit'), findsOneWidget);
    expect(find.text('Train smart.\nRecover better.'), findsOneWidget);
    expect(
      find.text('Kurze Empfehlungen passend zu deiner Schicht.'),
      findsOneWidget,
    );
    expect(find.text('Heute'), findsWidgets);
    expect(find.text('20 Min Training'), findsOneWidget);
    expect(find.text('Plan öffnen'), findsOneWidget);
    expect(find.text('Recovery Score'), findsOneWidget);
    expect(find.text('Dein Plan für heute'), findsOneWidget);
    expect(find.text('Schicht-Kompass'), findsOneWidget);
    expect(find.text('Recovery Tools'), findsOneWidget);
    expect(find.text('Wochenrhythmus'), findsOneWidget);
    expect(find.text('Sleep Anchor'), findsOneWidget);
    expect(find.text('Fuel Reminder'), findsOneWidget);
    expect(find.text('Breath Reset'), findsOneWidget);
    expect(find.text('Schichtarbeit. Training. Recovery.'), findsOneWidget);
  });

  testWidgets('Check-in updates recommendation for fatigue, night and strong energy', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ShiftFitApp());

    await tester.ensureVisible(find.byKey(const ValueKey('option-Müde')));
    await tester.tap(find.byKey(const ValueKey('option-Müde')));
    await tester.pumpAndSettle();
    expect(find.text('Recovery Flow'), findsOneWidget);
    expect(find.text('Runterfahren statt durchbeißen'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('option-Normal')));
    await tester.tap(find.byKey(const ValueKey('option-Normal')));
    await tester.ensureVisible(find.byKey(const ValueKey('option-Nacht')));
    await tester.tap(find.byKey(const ValueKey('option-Nacht')));
    await tester.pumpAndSettle();
    expect(find.text('Mobility Reset'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('option-Stark')));
    await tester.tap(find.byKey(const ValueKey('option-Stark')));
    await tester.pumpAndSettle();
    expect(find.text('Kraft Session'), findsOneWidget);
  });

  testWidgets('Plan sheet can be opened from today card', (WidgetTester tester) async {
    await tester.pumpWidget(const ShiftFitApp());

    await tester.ensureVisible(find.byKey(const ValueKey('today-open-plan')));
    await tester.tap(find.byKey(const ValueKey('today-open-plan')));
    await tester.pumpAndSettle();

    expect(find.text('Für heute vormerken'), findsOneWidget);
    expect(find.textContaining('Warm-up'), findsWidgets);
  });

  testWidgets('Bottom navigation switches between Heute, Woche and Trends', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ShiftFitApp());

    expect(find.text('Train smart.\nRecover better.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-Woche')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('screen-week')), findsOneWidget);
    expect(find.text('7 Tage,\nsauber getaktet.'), findsOneWidget);
    expect(find.text('Schichtplan'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-Trends')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('screen-trends')), findsOneWidget);
    expect(find.text('Readiness bleibt\nsteuerbar.'), findsOneWidget);
    expect(find.text('Readiness Verlauf'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-Heute')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('screen-today')), findsOneWidget);
    expect(find.text('Train smart.\nRecover better.'), findsOneWidget);
  });

  testWidgets('Week planner updates a day shift and summaries', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ShiftFitApp());

    await tester.tap(find.byKey(const ValueKey('nav-Woche')));
    await tester.pumpAndSettle();

    expect(find.text('1 geplant'), findsOneWidget);
    expect(find.text('4 Tage'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('week-Mo-Nacht')));
    await tester.pumpAndSettle();

    expect(find.text('2 geplant'), findsOneWidget);
    expect(find.text('3 Tage'), findsOneWidget);
  });
}

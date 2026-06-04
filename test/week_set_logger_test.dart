import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shiftfit/src/models/shift_fit_plan.dart';
import 'package:shiftfit/src/models/workout_set.dart';
import 'package:shiftfit/src/screens/week_planner_screen.dart';

// PROD-5: Set-Logger-Affordance auf dem WeekPlannerScreen.
// - Default (keine workoutHistory/onLogSet) -> Affordance versteckt
//   (haelt die bestehenden WeekPlannerScreen-Tests gruen).
// - Mit injizierten Params -> Karte sichtbar, Sheet oeffnet, Satz loggen
//   ruft den Callback mit den eingegebenen Werten.

ShiftFitPlan _plan() => ShiftFitPlan.from(
      shift: 'Kraft',
      energy: 'Stark',
      stress: 'Niedrig',
    );

Widget _host({
  List<WorkoutSet>? history,
  Future<void> Function(WorkoutSet)? onLogSet,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: WeekPlannerScreen(
          plan: _plan(),
          weekPlan: const [
            'Kraft',
            'Mobility',
            'Muskelaufbau',
            'Ausdauer',
            'Recovery',
            'Frei',
            'Kraft',
          ],
          onShiftChanged: (_, __) {},
          workoutHistory: history,
          onLogSet: onLogSet,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('Affordance ist versteckt ohne injizierte Logging-Params',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('screen-week')), findsOneWidget);
    expect(find.byKey(const ValueKey('week-log-workout')), findsNothing);
  });

  testWidgets('Mit Params: Karte sichtbar, Sheet oeffnet, Satz loggt Callback',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final logged = <WorkoutSet>[];
    await tester.pumpWidget(_host(
      history: const <WorkoutSet>[],
      onLogSet: (s) async => logged.add(s),
    ));
    await tester.pumpAndSettle();

    final card = find.byKey(const ValueKey('week-log-workout'));
    expect(card, findsOneWidget);

    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pumpAndSettle();

    // Default-Uebung = erste der Bibliothek (squat / Kniebeuge).
    expect(find.byKey(const ValueKey('set-weight-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('set-reps-field')), findsOneWidget);

    await tester.enterText(
        find.byKey(const ValueKey('set-weight-field')), '80');
    await tester.enterText(
        find.byKey(const ValueKey('set-reps-field')), '5');
    await tester.tap(find.byKey(const ValueKey('set-add')));
    await tester.pumpAndSettle();

    expect(logged.length, 1);
    expect(logged.first.weightKg, 80);
    expect(logged.first.reps, 5);
    expect(logged.first.exerciseId, 'squat');
  });

  testWidgets('Leere Eingabe zeigt Fehler, loggt nichts', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final logged = <WorkoutSet>[];
    await tester.pumpWidget(_host(
      history: const <WorkoutSet>[],
      onLogSet: (s) async => logged.add(s),
    ));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const ValueKey('week-log-workout')));
    await tester.tap(find.byKey(const ValueKey('week-log-workout')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('set-add')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('set-error')), findsOneWidget);
    expect(logged, isEmpty);
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:shiftfit/src/models/exercise.dart';
import 'package:shiftfit/src/models/workout_set.dart';

// PROD-5: WorkoutSet Row-Roundtrip + derived getters + Exercise library.
// Verifiziert dass toRow()/fromRow() byte-genau hin- und zurueck mappen,
// die defensive Fallback-Logik greift und die Epley/Volumen-Getter stimmen.

void main() {
  group('WorkoutSet roundtrip', () {
    test('toRow -> fromRow erhaelt alle Felder (mit RPE)', () {
      final loggedAt = DateTime(2026, 6, 4, 18, 30);
      final set = WorkoutSet(
        id: 'abc-123',
        exerciseId: 'bench_press',
        weightKg: 82.5,
        reps: 5,
        rpe: 8,
        loggedAt: loggedAt,
        localDay: '2026-06-04',
      );

      final row = set.toRow();
      // toRow serialisiert logged_at als UTC-ISO, exercise statt exerciseId.
      expect(row['id'], 'abc-123');
      expect(row['exercise'], 'bench_press');
      expect(row['weight_kg'], 82.5);
      expect(row['reps'], 5);
      expect(row['rpe'], 8);
      expect(row['local_day'], '2026-06-04');
      expect(row['logged_at'], loggedAt.toUtc().toIso8601String());

      final back = WorkoutSet.fromRow(row);
      expect(back.id, 'abc-123');
      expect(back.exerciseId, 'bench_press');
      expect(back.weightKg, 82.5);
      expect(back.reps, 5);
      expect(back.rpe, 8);
      expect(back.localDay, '2026-06-04');
      // logged_at roundtrip auf die Sekunde genau (UTC -> local).
      expect(back.loggedAt.toUtc().toIso8601String(),
          loggedAt.toUtc().toIso8601String());
    });

    test('fromRow ohne RPE -> null', () {
      final row = WorkoutSet(
        id: 'x',
        exerciseId: 'squat',
        weightKg: 100,
        reps: 3,
        loggedAt: DateTime(2026, 6, 4),
        localDay: '2026-06-04',
      ).toRow();
      expect(row['rpe'], isNull);
      expect(WorkoutSet.fromRow(row).rpe, isNull);
    });

    test('fromRow ist defensiv: fehlendes local_day wird rekonstruiert', () {
      final loggedAt = DateTime(2026, 3, 9, 14, 0);
      final back = WorkoutSet.fromRow({
        'id': 'y',
        'exercise': 'deadlift',
        'weight_kg': '140',
        'reps': '2',
        'logged_at': loggedAt.toUtc().toIso8601String(),
        // local_day bewusst weggelassen
      });
      expect(back.weightKg, 140);
      expect(back.reps, 2);
      // local_day rekonstruiert aus loggedAt.toLocal() -> YYYY-MM-DD.
      expect(back.localDay, isNotEmpty);
      expect(back.localDay, matches(r'^\d{4}-\d{2}-\d{2}$'));
    });

    test('fromRow toleriert Komma-Dezimalzahlen im Gewicht', () {
      final back = WorkoutSet.fromRow({
        'id': 'z',
        'exercise': 'squat',
        'weight_kg': '62,5',
        'reps': 8,
        'logged_at': DateTime(2026, 6, 4).toUtc().toIso8601String(),
        'local_day': '2026-06-04',
      });
      expect(back.weightKg, 62.5);
    });

    test('copyWith aendert nur das uebergebene Feld', () {
      final set = WorkoutSet(
        id: 'a',
        exerciseId: 'squat',
        weightKg: 100,
        reps: 5,
        loggedAt: DateTime(2026, 6, 4),
        localDay: '2026-06-04',
      );
      final updated = set.copyWith(reps: 6);
      expect(updated.reps, 6);
      expect(updated.weightKg, 100);
      expect(updated.exerciseId, 'squat');
      expect(updated.id, 'a');
    });
  });

  group('WorkoutSet derived getters', () {
    test('estimatedOneRepMax folgt Epley (weight * (1 + reps/30))', () {
      final set = WorkoutSet(
        id: 'a',
        exerciseId: 'bench_press',
        weightKg: 100,
        reps: 10,
        loggedAt: DateTime(2026, 6, 4),
        localDay: '2026-06-04',
      );
      // 100 * (1 + 10/30) = 133.33...
      expect(set.estimatedOneRepMax, closeTo(133.333, 0.01));
    });

    test('volume = weight * reps', () {
      final set = WorkoutSet(
        id: 'a',
        exerciseId: 'squat',
        weightKg: 80,
        reps: 5,
        loggedAt: DateTime(2026, 6, 4),
        localDay: '2026-06-04',
      );
      expect(set.volume, 400);
    });
  });

  group('Exercise library', () {
    test('byId findet bekannte Uebung, null fuer unbekannte', () {
      expect(Exercise.byId('bench_press')?.name, 'Bankdrücken');
      expect(Exercise.byId('does_not_exist'), isNull);
    });

    test('displayName faellt lesbar zurueck fuer entfernten Slug', () {
      expect(Exercise.displayName('squat'), 'Kniebeuge');
      expect(Exercise.displayName('old_removed_lift'), 'old removed lift');
      expect(Exercise.displayName(''), 'Übung');
    });

    test('Slugs sind eindeutig', () {
      final ids = exerciseLibrary.map((e) => e.id).toList();
      expect(ids.toSet().length, ids.length);
    });
  });
}

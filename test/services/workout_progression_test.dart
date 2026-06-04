import 'package:flutter_test/flutter_test.dart';

import 'package:shiftfit/src/models/workout_set.dart';
import 'package:shiftfit/src/services/workout_progression.dart';

// PROD-5: reine Progressions-Logik (kein I/O). lastSetFor / personalRecord /
// estimatedOneRepMax / sessionVolume.

WorkoutSet _set({
  required String exercise,
  required double weight,
  required int reps,
  required DateTime at,
}) {
  return WorkoutSet(
    id: '$exercise-${at.millisecondsSinceEpoch}-$weight-$reps',
    exerciseId: exercise,
    weightKg: weight,
    reps: reps,
    loggedAt: at,
    localDay: '2026-06-04',
  );
}

void main() {
  final d1 = DateTime(2026, 6, 1, 9);
  final d2 = DateTime(2026, 6, 3, 9);
  final d3 = DateTime(2026, 6, 4, 9);

  group('lastSetFor', () {
    test('liefert den zeitlich juengsten Satz der Uebung', () {
      final history = [
        _set(exercise: 'bench_press', weight: 80, reps: 5, at: d1),
        _set(exercise: 'bench_press', weight: 85, reps: 4, at: d3),
        _set(exercise: 'bench_press', weight: 82, reps: 5, at: d2),
        _set(exercise: 'squat', weight: 120, reps: 5, at: d3),
      ];
      final last = WorkoutProgression.lastSetFor('bench_press', history);
      expect(last, isNotNull);
      expect(last!.weightKg, 85);
      expect(last.loggedAt, d3);
    });

    test('Reihenfolge der History ist egal (max loggedAt gewinnt)', () {
      final history = [
        _set(exercise: 'squat', weight: 100, reps: 5, at: d3),
        _set(exercise: 'squat', weight: 90, reps: 5, at: d1),
      ];
      expect(WorkoutProgression.lastSetFor('squat', history)!.weightKg, 100);
    });

    test('null wenn Uebung nie geloggt wurde', () {
      final history = [_set(exercise: 'squat', weight: 100, reps: 5, at: d1)];
      expect(WorkoutProgression.lastSetFor('deadlift', history), isNull);
      expect(WorkoutProgression.lastSetFor('squat', const []), isNull);
    });
  });

  group('personalRecord', () {
    test('maxWeight und est-1RM koennen aus verschiedenen Saetzen stammen', () {
      final history = [
        // schwerer Single -> hoechstes Gewicht
        _set(exercise: 'deadlift', weight: 200, reps: 1, at: d1),
        // leichter aber viele Reps -> hoeheres est-1RM
        _set(exercise: 'deadlift', weight: 180, reps: 8, at: d2),
      ];
      final pr = WorkoutProgression.personalRecord('deadlift', history);
      expect(pr, isNotNull);
      expect(pr!.maxWeightKg, 200);
      // 180 * (1 + 8/30) = 228 > 200 (single)
      expect(pr.estimatedOneRepMax, closeTo(228.0, 0.01));
    });

    test('Single-Satz: maxWeight == est-1RM', () {
      final history = [
        _set(exercise: 'bench_press', weight: 100, reps: 1, at: d1),
      ];
      final pr = WorkoutProgression.personalRecord('bench_press', history)!;
      expect(pr.maxWeightKg, 100);
      expect(pr.estimatedOneRepMax, closeTo(100.0, 0.01));
    });

    test('null wenn keine Saetze fuer die Uebung', () {
      expect(WorkoutProgression.personalRecord('squat', const []), isNull);
      final history = [_set(exercise: 'squat', weight: 1, reps: 1, at: d1)];
      expect(WorkoutProgression.personalRecord('deadlift', history), isNull);
    });
  });

  group('estimatedOneRepMax', () {
    test('Epley fuer mehrere Reps', () {
      // 100 * (1 + 5/30) = 116.66...
      expect(WorkoutProgression.estimatedOneRepMax(100, 5),
          closeTo(116.667, 0.01));
    });

    test('reps <= 1 -> Gewicht selbst', () {
      expect(WorkoutProgression.estimatedOneRepMax(140, 1), 140);
      expect(WorkoutProgression.estimatedOneRepMax(140, 0), 140);
    });
  });

  group('sessionVolume', () {
    test('summiert Gewicht * Wiederholungen', () {
      final sets = [
        _set(exercise: 'squat', weight: 100, reps: 5, at: d1), // 500
        _set(exercise: 'squat', weight: 100, reps: 5, at: d1), // 500
        _set(exercise: 'bench_press', weight: 80, reps: 8, at: d1), // 640
      ];
      expect(WorkoutProgression.sessionVolume(sets), 1640);
    });

    test('leere Liste -> 0', () {
      expect(WorkoutProgression.sessionVolume(const []), 0);
    });
  });
}

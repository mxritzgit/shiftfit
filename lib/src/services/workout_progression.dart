import '../models/workout_set.dart';

/// Reine, testbare Progressions-Logik fuer Workout-Logs (PROD-5).
///
/// KEIN I/O, kein Supabase, kein Flutter — nimmt eine Historie von
/// WorkoutSet entgegen und leitet Kennzahlen ab. So bleibt die Logik
/// deterministisch und ohne Mock-Client unit-testbar (Stil von
/// kcal_calculator / meal_totals).
class WorkoutProgression {
  const WorkoutProgression._();

  /// Letzter (zeitlich juengster) geloggter Satz fuer [exerciseId] aus
  /// [history]; null wenn die Uebung nie geloggt wurde. „Juengster" =
  /// groesstes loggedAt — die Reihenfolge von [history] ist egal.
  static WorkoutSet? lastSetFor(String exerciseId, List<WorkoutSet> history) {
    WorkoutSet? best;
    for (final s in history) {
      if (s.exerciseId != exerciseId) continue;
      if (best == null || s.loggedAt.isAfter(best.loggedAt)) {
        best = s;
      }
    }
    return best;
  }

  /// Persoenlicher Rekord fuer [exerciseId] aus [history], oder null wenn
  /// die Uebung nie geloggt wurde. Liefert das schwerste je geloggte Gewicht
  /// (maxWeightKg) UND das hoechste geschaetzte 1RM (Epley:
  /// weight * (1 + reps / 30)). Beide koennen aus unterschiedlichen Saetzen
  /// stammen (ein schwerer Single vs. ein leichterer Satz mit vielen Reps).
  static PersonalRecord? personalRecord(
    String exerciseId,
    List<WorkoutSet> history,
  ) {
    double? maxWeight;
    double? maxOneRepMax;
    var found = false;
    for (final s in history) {
      if (s.exerciseId != exerciseId) continue;
      found = true;
      if (maxWeight == null || s.weightKg > maxWeight) {
        maxWeight = s.weightKg;
      }
      final orm = s.estimatedOneRepMax;
      if (maxOneRepMax == null || orm > maxOneRepMax) {
        maxOneRepMax = orm;
      }
    }
    if (!found) return null;
    return PersonalRecord(
      exerciseId: exerciseId,
      maxWeightKg: maxWeight ?? 0,
      estimatedOneRepMax: maxOneRepMax ?? 0,
    );
  }

  /// Geschaetztes 1RM nach Epley fuer einen einzelnen Satz:
  /// weight * (1 + reps / 30). Bei reps <= 1 == weight.
  static double estimatedOneRepMax(double weightKg, int reps) {
    if (reps <= 1) return weightKg;
    return weightKg * (1 + reps / 30.0);
  }

  /// Gesamt-Volumen (Summe Gewicht * Wiederholungen) der uebergebenen
  /// [sets] — z.B. die Saetze einer Session. 0 fuer eine leere Liste.
  static double sessionVolume(List<WorkoutSet> sets) {
    var total = 0.0;
    for (final s in sets) {
      total += s.volume;
    }
    return total;
  }
}

/// Persoenlicher Rekord einer Uebung. maxWeightKg = schwerstes je geloggtes
/// Gewicht; estimatedOneRepMax = hoechstes geschaetztes 1RM ueber alle Saetze.
class PersonalRecord {
  const PersonalRecord({
    required this.exerciseId,
    required this.maxWeightKg,
    required this.estimatedOneRepMax,
  });

  final String exerciseId;
  final double maxWeightKg;
  final double estimatedOneRepMax;
}

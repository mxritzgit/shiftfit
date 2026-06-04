import '../services/local_day.dart';

/// Ein einzelner geloggter Arbeitssatz (PROD-5: echtes Workout-Logging).
///
/// Eine WorkoutSet-Instanz == eine Zeile in public.workout_sets. Immutable
/// mit copyWith + toRow/fromRow im Stil von LifetimeStats/FitnessRecipe:
///  - toRow() serialisiert fuer ein upsert (user_id setzt der Sync, nicht
///    das Modell — exakt wie LoggedMeal/FitnessRecipe es halten).
///  - fromRow() ist defensiv: fehlende/falsch-getypte Spalten fallen auf
///    sinnvolle Defaults zurueck, damit ein altes Schema nicht crasht.
class WorkoutSet {
  const WorkoutSet({
    required this.id,
    required this.exerciseId,
    required this.weightKg,
    required this.reps,
    required this.loggedAt,
    required this.localDay,
    this.rpe,
  });

  /// Client-seitige UUID v4 (Primary Key). Idempotenter Upsert-Schluessel,
  /// genau wie bei LoggedMeal.
  final String id;

  /// Slug der Uebung (siehe Exercise.id). Landet in der exercise-Spalte.
  final String exerciseId;

  /// Gewicht in Kilogramm. double, damit z.B. 2,5-kg-Spruenge moeglich sind.
  final double weightKg;

  /// Wiederholungen in diesem Satz (>= 0).
  final int reps;

  /// Optionale Rate of Perceived Exertion (1..10), null wenn nicht erfasst.
  final int? rpe;

  /// Zeitpunkt des Loggens (lokal in der App, als UTC persistiert).
  final DateTime loggedAt;

  /// Kanonischer lokaler Tages-Schluessel `YYYY-MM-DD` (siehe local_day.dart).
  /// Identisches Format wie logged_meals.local_day — erlaubt das Bucketing
  /// einer Session ohne UTC-Drift.
  final String localDay;

  /// Geschaetztes 1-Rep-Maximum dieses Satzes nach Epley:
  /// weight * (1 + reps / 30). Bei reps <= 1 == weightKg.
  double get estimatedOneRepMax =>
      reps <= 1 ? weightKg : weightKg * (1 + reps / 30.0);

  /// Volumen dieses Satzes (Gewicht * Wiederholungen).
  double get volume => weightKg * reps;

  WorkoutSet copyWith({
    String? id,
    String? exerciseId,
    double? weightKg,
    int? reps,
    int? rpe,
    DateTime? loggedAt,
    String? localDay,
  }) {
    return WorkoutSet(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      weightKg: weightKg ?? this.weightKg,
      reps: reps ?? this.reps,
      rpe: rpe ?? this.rpe,
      loggedAt: loggedAt ?? this.loggedAt,
      localDay: localDay ?? this.localDay,
    );
  }

  /// Serialisiert fuer ein upsert auf public.workout_sets. user_id setzt der
  /// WorkoutLogSync, nicht das Modell. logged_at wandert als UTC-ISO-String.
  Map<String, dynamic> toRow() {
    return <String, dynamic>{
      'id': id,
      'exercise': exerciseId,
      'weight_kg': weightKg,
      'reps': reps,
      'rpe': rpe,
      'logged_at': loggedAt.toUtc().toIso8601String(),
      'local_day': localDay,
    };
  }

  /// Baut einen WorkoutSet aus einer public.workout_sets-Zeile. Defensiv —
  /// fehlt local_day, wird er aus loggedAt.toLocal() rekonstruiert (gleiche
  /// Fallback-Logik wie LoggedMeal.effectiveLocalDay).
  factory WorkoutSet.fromRow(Map<String, dynamic> row) {
    final loggedAt = _toDate(row['logged_at']) ?? DateTime.now();
    final rawLocalDay = row['local_day']?.toString();
    return WorkoutSet(
      id: row['id']?.toString() ?? '',
      exerciseId: row['exercise']?.toString() ?? '',
      weightKg: _toDouble(row['weight_kg']),
      reps: _toInt(row['reps']),
      rpe: _toIntOrNull(row['rpe']),
      loggedAt: loggedAt,
      localDay: (rawLocalDay != null && rawLocalDay.isNotEmpty)
          ? rawLocalDay
          : localDayKey(loggedAt.toLocal()),
    );
  }

  static double _toDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '.')) ?? 0;
    return 0;
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static int? _toIntOrNull(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static DateTime? _toDate(Object? value) {
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value)?.toLocal();
    }
    return null;
  }
}

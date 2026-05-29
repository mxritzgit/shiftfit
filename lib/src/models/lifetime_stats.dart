/// Kumulierte Lebenszeit-Zaehler eines Users (1:1 public.lifetime_stats).
///
/// Additiv erweitert um Streak-Felder (currentStreak/longestStreak/
/// lastWorkoutDate), damit der Workout-Streak app-Neustarts ueberlebt.
/// Alle bestehenden Felder + increment-Methoden bleiben unveraendert,
/// damit Aufrufer (Home, ProfileScreen, kcal-Logik) byte-genau gleich
/// funktionieren.
class LifetimeStats {
  LifetimeStats({
    this.workoutsCompleted = 0,
    this.mealsLogged = 0,
    this.waterTotalMl = 0,
    this.stepsRecorded = 0,
    this.weightLogs = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastWorkoutDate,
    DateTime? sessionStart,
  }) : sessionStart = sessionStart ?? DateTime.now();

  final int workoutsCompleted;
  final int mealsLogged;
  final int waterTotalMl;
  final int stepsRecorded;
  final int weightLogs;

  /// Aktuelle Workout-Streak in aufeinanderfolgenden Tagen.
  final int currentStreak;

  /// Hoechste je erreichte Streak (Highscore, nie absteigend).
  final int longestStreak;

  /// Datum (date-only) des letzten gezaehlten Workout-Tages, oder null.
  final DateTime? lastWorkoutDate;

  final DateTime sessionStart;

  Duration get sessionDuration => DateTime.now().difference(sessionStart);

  LifetimeStats copyWith({
    int? workoutsCompleted,
    int? mealsLogged,
    int? waterTotalMl,
    int? stepsRecorded,
    int? weightLogs,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastWorkoutDate,
  }) {
    return LifetimeStats(
      workoutsCompleted: workoutsCompleted ?? this.workoutsCompleted,
      mealsLogged: mealsLogged ?? this.mealsLogged,
      waterTotalMl: waterTotalMl ?? this.waterTotalMl,
      stepsRecorded: stepsRecorded ?? this.stepsRecorded,
      weightLogs: weightLogs ?? this.weightLogs,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastWorkoutDate: lastWorkoutDate ?? this.lastWorkoutDate,
      sessionStart: sessionStart,
    );
  }

  LifetimeStats incrementWorkouts() =>
      copyWith(workoutsCompleted: workoutsCompleted + 1);

  LifetimeStats incrementMeals() =>
      copyWith(mealsLogged: mealsLogged + 1);

  LifetimeStats addWater(int ml) =>
      copyWith(waterTotalMl: waterTotalMl + ml);

  LifetimeStats addSteps(int amount) =>
      copyWith(stepsRecorded: stepsRecorded + amount);

  LifetimeStats incrementWeightLogs() =>
      copyWith(weightLogs: weightLogs + 1);

  /// Verbucht einen abgeschlossenen Workout-Tag und fuehrt den Streak fort.
  ///
  /// - War das letzte Workout *gestern* (relativ zu [day]), zaehlt der
  ///   Streak +1 weiter.
  /// - War das letzte Workout *heute* (selber Tag), bleibt der Streak
  ///   unveraendert (idempotent — doppeltes Abhaken am gleichen Tag zaehlt
  ///   nicht doppelt), nur lastWorkoutDate wird auf [day] normalisiert.
  /// - Sonst (Luecke ≥ 1 Tag oder erster Workout) Reset auf 1.
  /// longestStreak = max(longestStreak, currentStreak danach).
  LifetimeStats recordWorkoutDay(DateTime day) {
    final today = DateTime(day.year, day.month, day.day);
    int nextStreak;
    if (lastWorkoutDate == null) {
      nextStreak = 1;
    } else {
      final last = DateTime(
        lastWorkoutDate!.year,
        lastWorkoutDate!.month,
        lastWorkoutDate!.day,
      );
      final diffDays = today.difference(last).inDays;
      if (diffDays == 0) {
        // Schon heute gezaehlt — idempotent, Streak haelt.
        nextStreak = currentStreak < 1 ? 1 : currentStreak;
      } else if (diffDays == 1) {
        nextStreak = currentStreak + 1;
      } else {
        // Luecke (oder Zukunft) — Streak gerissen, Neustart bei 1.
        nextStreak = 1;
      }
    }
    final nextLongest = nextStreak > longestStreak ? nextStreak : longestStreak;
    return copyWith(
      currentStreak: nextStreak,
      longestStreak: nextLongest,
      lastWorkoutDate: today,
    );
  }

  /// Baut LifetimeStats aus einer public.lifetime_stats-Zeile. Defensiv:
  /// fehlende/falsch-getypte Spalten fallen auf Defaults zurueck, damit
  /// ein altes Schema (vor der Streak-Migration) nicht crasht.
  factory LifetimeStats.fromRow(Map<String, dynamic> row) {
    return LifetimeStats(
      workoutsCompleted: _toInt(row['workouts_completed']),
      mealsLogged: _toInt(row['meals_logged']),
      waterTotalMl: _toInt(row['water_total_ml']),
      stepsRecorded: _toInt(row['steps_recorded']),
      weightLogs: _toInt(row['weight_logs']),
      currentStreak: _toInt(row['current_streak']),
      longestStreak: _toInt(row['longest_streak']),
      lastWorkoutDate: _toDate(row['last_workout_date']),
      sessionStart: _toDate(row['session_start']),
    );
  }

  /// Serialisiert fuer ein upsert auf public.lifetime_stats. session_start
  /// wird bewusst NICHT mitgeschrieben — der erste Insert setzt es per
  /// DB-Default, spaetere Saves sollen es nicht ueberschreiben.
  Map<String, dynamic> toRow() {
    return <String, dynamic>{
      'workouts_completed': workoutsCompleted,
      'meals_logged': mealsLogged,
      'water_total_ml': waterTotalMl,
      'steps_recorded': stepsRecorded,
      'weight_logs': weightLogs,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'last_workout_date':
          lastWorkoutDate == null ? null : _dateOnly(lastWorkoutDate!),
    };
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime? _toDate(Object? value) {
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static String _dateOnly(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}

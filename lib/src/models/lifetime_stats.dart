class LifetimeStats {
  LifetimeStats({
    this.workoutsCompleted = 0,
    this.mealsLogged = 0,
    this.waterTotalMl = 0,
    this.stepsRecorded = 0,
    this.weightLogs = 0,
    DateTime? sessionStart,
  }) : sessionStart = sessionStart ?? DateTime.now();

  final int workoutsCompleted;
  final int mealsLogged;
  final int waterTotalMl;
  final int stepsRecorded;
  final int weightLogs;
  final DateTime sessionStart;

  Duration get sessionDuration => DateTime.now().difference(sessionStart);

  LifetimeStats copyWith({
    int? workoutsCompleted,
    int? mealsLogged,
    int? waterTotalMl,
    int? stepsRecorded,
    int? weightLogs,
  }) {
    return LifetimeStats(
      workoutsCompleted: workoutsCompleted ?? this.workoutsCompleted,
      mealsLogged: mealsLogged ?? this.mealsLogged,
      waterTotalMl: waterTotalMl ?? this.waterTotalMl,
      stepsRecorded: stepsRecorded ?? this.stepsRecorded,
      weightLogs: weightLogs ?? this.weightLogs,
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
}

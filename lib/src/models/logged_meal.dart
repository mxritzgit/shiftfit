import 'meal_analysis_result.dart';

enum MealSlot { breakfast, lunch, dinner, snack }

extension MealSlotLabel on MealSlot {
  String get label => switch (this) {
        MealSlot.breakfast => 'Frühstück',
        MealSlot.lunch => 'Mittagessen',
        MealSlot.dinner => 'Abendessen',
        MealSlot.snack => 'Snacks',
      };
}

class LoggedMeal {
  const LoggedMeal({
    required this.id,
    required this.result,
    required this.loggedAt,
    this.forcedSlot,
  });

  final String id;
  final MealAnalysisResult result;
  final DateTime loggedAt;
  final MealSlot? forcedSlot;

  MealSlot get slot {
    if (forcedSlot != null) {
      return forcedSlot!;
    }
    final hour = loggedAt.hour;
    if (hour < 11) return MealSlot.breakfast;
    if (hour < 15) return MealSlot.lunch;
    if (hour < 21) return MealSlot.dinner;
    return MealSlot.snack;
  }

  LoggedMeal copyWith({
    MealAnalysisResult? result,
    MealSlot? forcedSlot,
  }) {
    return LoggedMeal(
      id: id,
      result: result ?? this.result,
      loggedAt: loggedAt,
      forcedSlot: forcedSlot ?? this.forcedSlot,
    );
  }
}

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
  });

  final String id;
  final MealAnalysisResult result;
  final DateTime loggedAt;

  MealSlot get slot {
    final hour = loggedAt.hour;
    if (hour < 11) return MealSlot.breakfast;
    if (hour < 15) return MealSlot.lunch;
    if (hour < 21) return MealSlot.dinner;
    return MealSlot.snack;
  }

  LoggedMeal copyWith({MealAnalysisResult? result}) {
    return LoggedMeal(
      id: id,
      result: result ?? this.result,
      loggedAt: loggedAt,
    );
  }
}

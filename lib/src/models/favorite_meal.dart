import 'meal_analysis_result.dart';

class FavoriteMeal {
  const FavoriteMeal({required this.id, required this.result, required this.addedAt});

  final String id;
  final MealAnalysisResult result;
  final DateTime addedAt;

  static String idFor(MealAnalysisResult result) {
    final barcode = result.barcode;
    if (barcode != null && barcode.isNotEmpty) {
      return 'barcode:$barcode';
    }
    return 'name:${result.mealName.toLowerCase().trim()}';
  }
}

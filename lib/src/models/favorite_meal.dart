import 'meal_analysis_result.dart';

class FavoriteMeal {
  const FavoriteMeal({
    required this.id,
    required this.result,
    required this.addedAt,
    this.pinned = false,
  });

  final String id;
  final MealAnalysisResult result;
  final DateTime addedAt;

  /// True = vom User explizit als Favorit angeheftet (Herz). False = nur ein
  /// Auto-Recent (zuletzt geloggt). Das Kappen auf die letzten N betrifft NUR
  /// die Auto-Recents — angeheftete Favoriten bleiben dauerhaft erhalten.
  final bool pinned;

  FavoriteMeal copyWith({bool? pinned, DateTime? addedAt}) {
    return FavoriteMeal(
      id: id,
      result: result,
      addedAt: addedAt ?? this.addedAt,
      pinned: pinned ?? this.pinned,
    );
  }

  static String idFor(MealAnalysisResult result) {
    final barcode = result.barcode;
    if (barcode != null && barcode.isNotEmpty) {
      return 'barcode:$barcode';
    }
    return 'name:${result.mealName.toLowerCase().trim()}';
  }
}

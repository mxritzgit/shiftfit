import 'meal_analysis_result.dart';

class MacroProgress {
  const MacroProgress({
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.kcal,
  });

  final double proteinG;
  final double carbsG;
  final double fatG;
  final int kcal;

  MacroProgress add(MealAnalysisResult result) {
    return MacroProgress(
      proteinG: proteinG + _parseMacroG(result.protein),
      carbsG: carbsG + _parseMacroG(result.carbs),
      fatG: fatG + _parseMacroG(result.fat),
      kcal: kcal + result.caloriesKcal,
    );
  }

  MacroProgress subtract(MealAnalysisResult result) {
    return MacroProgress(
      proteinG: (proteinG - _parseMacroG(result.protein)).clamp(0, double.infinity),
      carbsG: (carbsG - _parseMacroG(result.carbs)).clamp(0, double.infinity),
      fatG: (fatG - _parseMacroG(result.fat)).clamp(0, double.infinity),
      kcal: (kcal - result.caloriesKcal).clamp(0, 1 << 30),
    );
  }

  static const empty = MacroProgress(proteinG: 0, carbsG: 0, fatG: 0, kcal: 0);

  static double _parseMacroG(String value) {
    final match = RegExp(r'(\d+(?:[.,]\d+)?)').firstMatch(value);
    if (match == null) {
      return 0;
    }
    return double.tryParse(match.group(1)!.replaceAll(',', '.')) ?? 0;
  }
}

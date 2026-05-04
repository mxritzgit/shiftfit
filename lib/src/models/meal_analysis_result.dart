import 'meal_component.dart';

class MealAnalysisResult {
  const MealAnalysisResult({
    required this.mealName,
    required this.caloriesKcal,
    required this.estimatedGrams,
    required this.kcalPer100G,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.confidence,
    required this.portionNotes,
    this.items = const [],
    this.isAdjusted = false,
    this.sourceLabel = 'KI-Schätzung',
    this.barcode,
    this.brand,
  });

  final String mealName;
  final int caloriesKcal;
  final int estimatedGrams;
  final double kcalPer100G;
  final String protein;
  final String carbs;
  final String fat;
  final String confidence;
  final String portionNotes;
  final List<MealComponent> items;
  final bool isAdjusted;
  final String sourceLabel;
  final String? barcode;
  final String? brand;

  String get kcalRange => '$caloriesKcal kcal';
  String get portionLabel => '$estimatedGrams g geschätzt';
  String get kcalPer100Label => '${kcalPer100G.round()} kcal / 100 g';
  bool get hasItemizedBreakdown => items.isNotEmpty;

  MealAnalysisResult adjustedToGrams(int grams) {
    final factor = estimatedGrams <= 0 ? 1.0 : grams / estimatedGrams;
    final adjustedItems = hasItemizedBreakdown
        ? items
              .map((item) => item.adjustedToGrams((item.grams * factor).round()))
              .toList(growable: false)
        : items;
    final adjustedKcal = (kcalPer100G * grams / 100).round();
    return MealAnalysisResult(
      mealName: mealName,
      caloriesKcal: adjustedKcal,
      estimatedGrams: grams,
      kcalPer100G: kcalPer100G,
      protein: _scaleMacroText(protein, factor),
      carbs: _scaleMacroText(carbs, factor),
      fat: _scaleMacroText(fat, factor),
      confidence: confidence,
      portionNotes:
          'Manuell angepasst: $grams g statt der ursprünglichen Portion. Kalorien neu berechnet mit ${kcalPer100G.round()} kcal pro 100 g.',
      items: adjustedItems,
      isAdjusted: true,
      sourceLabel: sourceLabel,
      barcode: barcode,
      brand: brand,
    );
  }

  MealAnalysisResult adjustedToItems(List<MealComponent> adjustedItems) {
    final totalGrams = adjustedItems.fold<int>(0, (sum, item) => sum + item.grams);
    final totalKcal = adjustedItems.fold<int>(
      0,
      (sum, item) => sum + item.caloriesKcal,
    );
    final factor = estimatedGrams <= 0 ? 1.0 : totalGrams / estimatedGrams;

    return MealAnalysisResult(
      mealName: mealName,
      caloriesKcal: totalKcal,
      estimatedGrams: totalGrams,
      kcalPer100G: totalGrams > 0 ? totalKcal * 100 / totalGrams : kcalPer100G,
      protein: _scaleMacroText(protein, factor),
      carbs: _scaleMacroText(carbs, factor),
      fat: _scaleMacroText(fat, factor),
      confidence: confidence,
      portionNotes:
          'Einzelne Bestandteile wurden manuell bestätigt oder angepasst. Gesamtwerte wurden aus der Summe der Positionen neu berechnet.',
      items: adjustedItems,
      isAdjusted: true,
      sourceLabel: sourceLabel,
      barcode: barcode,
      brand: brand,
    );
  }

  factory MealAnalysisResult.fromEdgeFunction(Map<String, dynamic> json) {
    final mealName = json['mealName']?.toString() ?? 'Unbekannte Mahlzeit';
    final items = _readItems(json);
    final itemCalories = items.fold<int>(0, (sum, item) => sum + item.caloriesKcal);
    final itemGrams = items.fold<int>(0, (sum, item) => sum + item.grams);
    final calories = _readInt(json, const [
          'caloriesKcal',
          'kcal',
          'calories',
          'estimatedCaloriesKcal',
        ]) ??
        _extractFirstInt(json['caloriesKcal']?.toString()) ??
        _extractFirstInt(json['calories']?.toString()) ??
        (itemCalories > 0 ? itemCalories : 0);
    final estimatedGrams = _readInt(json, const [
          'estimatedGrams',
          'portionGrams',
          'grams',
          'weightG',
          'estimatedWeightG',
        ]) ??
        _estimateGramsFromText(json['explanation']?.toString()) ??
        (itemGrams > 0 ? itemGrams : 150);
    final kcalPer100G = _readDouble(json, const [
          'kcalPer100G',
          'caloriesPer100G',
          'caloriesPer100g',
          'kcalPer100g',
        ]) ??
        _knownKcalPer100G(mealName) ??
        ((estimatedGrams > 0 && calories > 0)
            ? calories * 100 / estimatedGrams
            : 52.0);
    final protein = json['proteinG'];
    final carbs = json['carbsG'];
    final fat = json['fatG'];
    final confidence = json['confidence']?.toString() ?? 'medium';
    final resolvedCalories =
        calories > 0 ? calories : (kcalPer100G * estimatedGrams / 100).round();
    final resolvedGrams = estimatedGrams > 0 ? estimatedGrams : itemGrams;
    final normalizedItems =
        itemGrams > 0 || itemCalories > 0 ? items : const <MealComponent>[];

    return MealAnalysisResult(
      mealName: mealName,
      caloriesKcal: resolvedCalories,
      estimatedGrams: resolvedGrams,
      kcalPer100G: kcalPer100G,
      protein: protein == null ? '-' : '$protein g',
      carbs: carbs == null ? '-' : '$carbs g',
      fat: fat == null ? '-' : '$fat g',
      confidence: _formatConfidence(confidence),
      portionNotes: json['explanation']?.toString() ??
          (normalizedItems.isNotEmpty
              ? 'KI-Schätzung aus dem Foto mit Einzelposten. Bitte Bestandteile und Gramm prüfen.'
              : 'KI-Schätzung aus dem Foto. Die Größe wurde nicht exakt vermessen; bitte Portion bestätigen oder Gewicht anpassen.'),
      items: normalizedItems,
      sourceLabel: 'Foto-KI',
    );
  }

  factory MealAnalysisResult.fromOpenFoodFacts(
    Map<String, dynamic> product,
    String barcode,
  ) {
    final nutriments = product['nutriments'] is Map<String, dynamic>
        ? product['nutriments'] as Map<String, dynamic>
        : <String, dynamic>{};
    final productName = _firstNonEmptyString(product, const [
          'product_name',
          'generic_name',
        ]) ??
        'Produkt $barcode';
    final brand = _firstNonEmptyString(product, const ['brands']);
    final kcalPer100G = _readDouble(nutriments, const [
          'energy-kcal_100g',
          'energy_kcal_100g',
          'energy-kcal_value',
        ]) ??
        0;
    final servingGrams = _readDouble(product, const ['serving_quantity'])?.round() ??
        _estimateGramsFromText(product['serving_size']?.toString()) ??
        100;
    final calories = (kcalPer100G * servingGrams / 100).round();
    final protein100 = _readDouble(nutriments, const ['proteins_100g']);
    final carbs100 = _readDouble(nutriments, const ['carbohydrates_100g']);
    final fat100 = _readDouble(nutriments, const ['fat_100g']);
    final quantity = _firstNonEmptyString(product, const ['quantity']);
    final servingSize = _firstNonEmptyString(product, const ['serving_size']);
    final details = <String>[
      'OpenFoodFacts Barcode $barcode.',
      if (brand != null) 'Marke: $brand.',
      if (quantity != null) 'Packung: $quantity.',
      if (servingSize != null) 'Portion laut Datenbank: $servingSize.',
      'Nährwerte kommen aus der Produktdatenbank, nicht aus einer Foto-Schätzung.',
      'Du kannst das gegessene Gewicht weiter anpassen.',
    ].join(' ');

    return MealAnalysisResult(
      mealName: brand == null ? productName : '$productName · $brand',
      caloriesKcal: calories,
      estimatedGrams: servingGrams,
      kcalPer100G: kcalPer100G,
      protein: _macroForGrams(protein100, servingGrams),
      carbs: _macroForGrams(carbs100, servingGrams),
      fat: _macroForGrams(fat100, servingGrams),
      confidence: 'Datenbank',
      portionNotes: details,
      sourceLabel: 'OpenFoodFacts',
      barcode: barcode,
      brand: brand,
    );
  }

  static List<MealComponent> _readItems(Map<String, dynamic> json) {
    for (final key in const ['items', 'components', 'foods', 'foodItems']) {
      final value = json[key];
      if (value is List) {
        return value
            .whereType<Map>()
            .map(
              (item) => MealComponent.fromJson(
                item.map(
                  (itemKey, itemValue) => MapEntry(itemKey.toString(), itemValue),
                ),
              ),
            )
            .where((item) => item.name.trim().isNotEmpty)
            .toList(growable: false);
      }
    }
    return const <MealComponent>[];
  }

  static int? _readInt(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is int) {
        return value;
      }
      if (value is double) {
        return value.round();
      }
      if (value is String) {
        final parsed = _extractFirstInt(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }

  static double? _readDouble(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        final normalized = value.replaceAll(',', '.');
        final match = RegExp(r'\d+(?:\.\d+)?').firstMatch(normalized);
        if (match != null) {
          return double.tryParse(match.group(0)!);
        }
      }
    }
    return null;
  }

  static String? _firstNonEmptyString(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  static String _macroForGrams(double? per100G, int grams) {
    if (per100G == null) {
      return '-';
    }
    final value = per100G * grams / 100;
    final formatted = value >= 10 ? value.round().toString() : value.toStringAsFixed(1);
    return '${formatted.replaceAll('.', ',')} g';
  }

  static int? _extractFirstInt(String? value) {
    if (value == null) {
      return null;
    }
    final match = RegExp(r'\d+').firstMatch(value);
    return match == null ? null : int.tryParse(match.group(0)!);
  }

  static int? _estimateGramsFromText(String? value) {
    if (value == null) {
      return null;
    }
    final match = RegExp(r'(\d{2,4})\s*g').firstMatch(value.toLowerCase());
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  static double? _knownKcalPer100G(String mealName) {
    final lower = mealName.toLowerCase();
    if (lower.contains('apfel') || lower.contains('apple')) {
      return 52;
    }
    if (lower.contains('banane') || lower.contains('banana')) {
      return 89;
    }
    if (lower.contains('orange')) {
      return 47;
    }
    if (lower.contains('erdbeer') || lower.contains('strawberr')) {
      return 32;
    }
    return null;
  }

  static String _scaleMacroText(String value, double factor) {
    final match = RegExp(r'(\d+(?:[,.]\d+)?)').firstMatch(value);
    if (match == null) {
      return value;
    }
    final number = double.tryParse(match.group(1)!.replaceAll(',', '.'));
    if (number == null) {
      return value;
    }
    final scaled = number * factor;
    final formatted = scaled >= 10 ? scaled.round().toString() : scaled.toStringAsFixed(1);
    return value.replaceFirst(match.group(1)!, formatted.replaceAll('.', ','));
  }

  static String _formatConfidence(String value) {
    switch (value.toLowerCase()) {
      case 'high':
        return 'Hoch';
      case 'medium':
        return 'Mittel';
      case 'low':
        return 'Niedrig';
      default:
        return value;
    }
  }
}

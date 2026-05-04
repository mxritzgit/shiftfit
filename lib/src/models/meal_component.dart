class MealComponent {
  const MealComponent({
    required this.name,
    required this.grams,
    required this.caloriesKcal,
    this.kcalPer100G,
  });

  final String name;
  final int grams;
  final int caloriesKcal;
  final double? kcalPer100G;

  String get gramsLabel => '$grams g';
  String get caloriesLabel => '$caloriesKcal kcal';

  MealComponent adjustedToGrams(int adjustedGrams) {
    final per100 =
        kcalPer100G ?? (grams > 0 ? caloriesKcal * 100 / grams : 0);
    return MealComponent(
      name: name,
      grams: adjustedGrams,
      caloriesKcal: (per100 * adjustedGrams / 100).round(),
      kcalPer100G: per100 <= 0 ? null : per100,
    );
  }

  factory MealComponent.fromJson(Map<String, dynamic> json) {
    final name =
        _firstNonEmptyString(json, const ['name', 'item', 'food', 'label']) ??
        'Zutat';
    final grams =
        _readInt(json, const [
          'grams',
          'estimatedGrams',
          'weightG',
          'quantityG',
          'portionGrams',
        ]) ??
        _extractFirstInt(json['grams']?.toString()) ??
        0;
    final kcalPer100 = _readDouble(json, const [
      'kcalPer100G',
      'caloriesPer100G',
      'caloriesPer100g',
      'kcalPer100g',
    ]);
    final calories =
        _readInt(json, const ['caloriesKcal', 'kcal', 'calories']) ??
        (kcalPer100 != null && grams > 0 ? (kcalPer100 * grams / 100).round() : 0);

    return MealComponent(
      name: name,
      grams: grams,
      caloriesKcal: calories,
      kcalPer100G: kcalPer100,
    );
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

  static int? _extractFirstInt(String? value) {
    if (value == null) {
      return null;
    }
    final match = RegExp(r'\d+').firstMatch(value);
    return match == null ? null : int.tryParse(match.group(0)!);
  }
}

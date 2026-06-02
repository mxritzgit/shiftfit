import 'package:flutter/material.dart';

import '../models/logged_meal.dart';
import 'app_colors.dart';

/// Zentrale UI-Stilzuordnung für [MealSlot] (Akzentfarbe, Tageszeit-Icon,
/// kompaktes Label). Vorher war dieses switch 5–6× über Widgets dupliziert
/// (add_meal_sheet, recipes_screen, meal_analysis_sheet, existing_meals_list)
/// und die Icons begannen zu divergieren. Eine Quelle der Wahrheit.
extension MealSlotStyle on MealSlot {
  Color get accent => switch (this) {
        MealSlot.breakfast => orange,
        MealSlot.lunch => lime,
        MealSlot.dinner => slotDinner,
        MealSlot.snack => cyan,
      };

  IconData get icon => switch (this) {
        MealSlot.breakfast => Icons.wb_sunny_outlined,
        MealSlot.lunch => Icons.light_mode_outlined,
        MealSlot.dinner => Icons.nights_stay_outlined,
        MealSlot.snack => Icons.cookie_outlined,
      };

  /// Kompaktes Label für enge Slots (Segmented-Control) — kürzer als das
  /// Modell-Label ([MealSlotLabel.label], z. B. „Mittagessen"/„Snacks").
  String get shortLabel => switch (this) {
        MealSlot.breakfast => 'Frühstück',
        MealSlot.lunch => 'Mittag',
        MealSlot.dinner => 'Abend',
        MealSlot.snack => 'Snack',
      };
}

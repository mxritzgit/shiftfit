import 'package:flutter/material.dart';

import '../models/favorite_meal.dart';
import '../models/logged_meal.dart';
import '../models/macro_progress.dart';
import '../models/meal_analysis_result.dart';
import '../models/user_profile.dart';
import '../services/meal_analyzer.dart';
import '../services/meal_photo_input.dart';
import '../services/open_food_facts_product_service.dart';
import '../theme/app_colors.dart';
import '../widgets/kcal/add_meal_sheet.dart';
import '../widgets/kcal/calories_overview_card.dart';

class MealAnalysisScreen extends StatelessWidget {
  MealAnalysisScreen({
    super.key,
    MealAnalyzer? analyzer,
    ProductLookupService? productService,
    MealPhotoInput? photoInput,
    required this.dailyConsumedKcal,
    this.macroProgress = MacroProgress.empty,
    this.profile = const UserProfile(),
    this.favorites = const <FavoriteMeal>[],
    this.loggedMeals = const <LoggedMeal>[],
    this.burnedKcal = 0,
    DateTime? selectedDate,
    ValueChanged<DateTime>? onDateSelected,
    this.visibleFutureDays = 4,
    void Function(MealAnalysisResult, MealSlot)? onAddMeal,
    ValueChanged<int>? onAdjustDailyKcal,
    ValueChanged<String>? onRemoveFavorite,
  }) : analyzer = analyzer ?? const EdgeFunctionMealAnalyzer(),
       productService = productService ?? const OpenFoodFactsProductService(),
       photoInput = photoInput ?? DeviceMealPhotoInput(),
       selectedDate = DateUtils.dateOnly(selectedDate ?? DateTime.now()),
       onDateSelected = onDateSelected ?? _noopDate,
       onAddMeal = onAddMeal ?? _noopAdd,
       onAdjustDailyKcal = onAdjustDailyKcal ?? _noopInt,
       onRemoveFavorite = onRemoveFavorite ?? _noopString;

  static void _noopAdd(MealAnalysisResult _, MealSlot __) {}
  static void _noopDate(DateTime _) {}
  static void _noopInt(int _) {}
  static void _noopString(String _) {}

  final MealAnalyzer analyzer;
  final ProductLookupService productService;
  final MealPhotoInput photoInput;
  final int dailyConsumedKcal;
  final MacroProgress macroProgress;
  final UserProfile profile;
  final List<FavoriteMeal> favorites;
  final List<LoggedMeal> loggedMeals;
  final int burnedKcal;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final int visibleFutureDays;
  final void Function(MealAnalysisResult, MealSlot) onAddMeal;
  final ValueChanged<int> onAdjustDailyKcal;
  final ValueChanged<String> onRemoveFavorite;

  void _openAddSheet(BuildContext context, MealSlot slot) {
    showAddMealSheet(
      context,
      slot: slot,
      analyzer: analyzer,
      productService: productService,
      photoInput: photoInput,
      favorites: favorites,
      onAdd: onAddMeal,
      onAdjustDailyKcal: onAdjustDailyKcal,
      onRemoveFavorite: onRemoveFavorite,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boundedHeight = constraints.hasBoundedHeight;
        final children = <Widget>[
          const _KcalHeader(),
          SizedBox(height: boundedHeight ? 6 : 4),
          _FoodDateStrip(
            selectedDate: selectedDate,
            futureDays: visibleFutureDays,
            onSelected: onDateSelected,
          ),
          SizedBox(height: boundedHeight ? 8 : 10),
          if (boundedHeight)
            Expanded(
              flex: 36,
              child: CaloriesOverviewCard(
                dailyConsumedKcal: dailyConsumedKcal,
                kcalGoal: profile.dailyKcalGoal,
                burnedKcal: burnedKcal,
              ),
            )
          else
            CaloriesOverviewCard(
              dailyConsumedKcal: dailyConsumedKcal,
              kcalGoal: profile.dailyKcalGoal,
              burnedKcal: burnedKcal,
            ),
          const SizedBox(height: 10),
          if (boundedHeight)
            Expanded(
              flex: 27,
              child: MacrosOverviewCard(
                progress: macroProgress,
                profile: profile,
              ),
            )
          else
            MacrosOverviewCard(
              progress: macroProgress,
              profile: profile,
            ),
          const SizedBox(height: 10),
          if (boundedHeight)
            Expanded(
              flex: 37,
              child: MealsTodayCard(
                meals: loggedMeals,
                onMealTap: (slot) => _openAddSheet(context, slot),
              ),
            )
          else
            MealsTodayCard(
              meals: loggedMeals,
              onMealTap: (slot) => _openAddSheet(context, slot),
            ),
        ];

        return SizedBox(
          key: const ValueKey('kcal-page-fill'),
          height: boundedHeight ? constraints.maxHeight : null,
          child: Column(
            key: const ValueKey('screen-kcal-tracker'),
            mainAxisSize: boundedHeight ? MainAxisSize.max : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        );
      },
    );
  }
}

class _KcalHeader extends StatelessWidget {
  const _KcalHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(2, 2, 0, 4),
      child: Text(
        'Kalorien',
        style: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}

class _FoodDateStrip extends StatelessWidget {
  const _FoodDateStrip({
    required this.selectedDate,
    required this.futureDays,
    required this.onSelected,
  });

  final DateTime selectedDate;
  final int futureDays;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final selected = DateUtils.dateOnly(selectedDate);
    final days = List<DateTime>.generate(
      futureDays + 1,
      (index) => today.add(Duration(days: index)),
    );

    return Container(
      key: const ValueKey('food-date-strip'),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_rounded, size: 15, color: lime),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _selectedLabel(today, selected),
                    key: const ValueKey('food-date-selected-label'),
                    style: const TextStyle(
                      color: textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                const Text(
                  'Planbar',
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              for (var index = 0; index < days.length; index++) ...[
                Expanded(
                  child: _FoodDateChip(
                    key: ValueKey('food-date-chip-$index'),
                    date: days[index],
                    label: _chipLabel(index),
                    selected: DateUtils.isSameDay(days[index], selected),
                    onTap: () => onSelected(days[index]),
                  ),
                ),
                if (index != days.length - 1) const SizedBox(width: 6),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static String _chipLabel(int offset) {
    if (offset == 0) return 'Heute';
    if (offset == 1) return 'Morgen';
    return '+$offset';
  }

  static String _selectedLabel(DateTime today, DateTime selected) {
    final offset = selected.difference(today).inDays;
    if (offset == 0) return 'Heute';
    if (offset == 1) return 'Morgen';
    return 'In $offset Tagen';
  }
}

class _FoodDateChip extends StatelessWidget {
  const _FoodDateChip({
    super.key,
    required this.date,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final DateTime date;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? lime : surfaceSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? lime : hairline,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? bg : textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${date.day}.${date.month}.',
              style: TextStyle(
                color: selected ? bg.withValues(alpha: 0.72) : textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

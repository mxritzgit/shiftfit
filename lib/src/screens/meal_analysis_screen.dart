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
    void Function(MealAnalysisResult, MealSlot)? onAddMeal,
    ValueChanged<int>? onAdjustDailyKcal,
    ValueChanged<String>? onRemoveFavorite,
  }) : analyzer = analyzer ?? const EdgeFunctionMealAnalyzer(),
       productService = productService ?? const OpenFoodFactsProductService(),
       photoInput = photoInput ?? DeviceMealPhotoInput(),
       onAddMeal = onAddMeal ?? _noopAdd,
       onAdjustDailyKcal = onAdjustDailyKcal ?? _noopInt,
       onRemoveFavorite = onRemoveFavorite ?? _noopString;

  static void _noopAdd(MealAnalysisResult _, MealSlot __) {}
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
    return Column(
      key: const ValueKey('screen-kcal-tracker'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _KcalHeader(),
        const SizedBox(height: 6),
        CaloriesOverviewCard(
          dailyConsumedKcal: dailyConsumedKcal,
          kcalGoal: profile.dailyKcalGoal,
          burnedKcal: burnedKcal,
        ),
        const SizedBox(height: 14),
        MacrosOverviewCard(
          progress: macroProgress,
          profile: profile,
        ),
        const SizedBox(height: 14),
        MealsTodayCard(
          meals: loggedMeals,
          onMealTap: (slot) => _openAddSheet(context, slot),
        ),
      ],
    );
  }
}

class _KcalHeader extends StatelessWidget {
  const _KcalHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 0, 8),
      child: Row(
        children: [
          const Text(
            'Kalorien',
            style: TextStyle(
              color: textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          _HeaderIconButton(
            icon: Icons.calendar_today_outlined,
            onTap: () {},
          ),
          const SizedBox(width: 8),
          _HeaderIconButton(
            icon: Icons.more_horiz_rounded,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 24,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: surface,
          shape: BoxShape.circle,
          border: Border.all(color: hairline),
        ),
        child: Icon(icon, color: textPrimary, size: 16),
      ),
    );
  }
}

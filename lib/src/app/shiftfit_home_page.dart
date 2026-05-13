import 'package:flutter/material.dart';

import '../models/favorite_meal.dart';
import '../models/macro_progress.dart';
import '../models/meal_analysis_result.dart';
import '../models/shift_fit_plan.dart';
import '../models/sleep_entry.dart';
import '../models/user_profile.dart';
import '../services/meal_analyzer.dart';
import '../services/meal_photo_input.dart';
import '../services/open_food_facts_product_service.dart';
import '../screens/meal_analysis_screen.dart';
import '../screens/today_dashboard.dart';
import '../screens/trends_screen.dart';
import '../screens/week_planner_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/app_shell/shiftfit_bottom_nav.dart';
import '../widgets/shared/settings_sheet.dart';
import '../widgets/today/wellness_widgets.dart';

class ShiftFitHomePage extends StatefulWidget {
  ShiftFitHomePage({
    super.key,
    this.mealAnalyzer,
    this.productService,
    this.photoInput,
  });

  final MealAnalyzer? mealAnalyzer;
  final ProductLookupService? productService;
  final MealPhotoInput? photoInput;

  @override
  State<ShiftFitHomePage> createState() => _ShiftFitHomePageState();
}

class _ShiftFitHomePageState extends State<ShiftFitHomePage> {
  String selectedShift = 'Früh';
  String selectedEnergy = 'Normal';
  String selectedStress = 'Mittel';
  int selectedTab = 0;
  int dailyConsumedKcal = 0;
  int dailyWaterMl = 0;
  UserProfile profile = const UserProfile();
  MacroProgress macroProgress = MacroProgress.empty;
  SleepEntry? lastSleep;
  Set<String> completedBlockIds = <String>{};
  int workoutStreak = 0;
  List<FavoriteMeal> favorites = <FavoriteMeal>[];
  final List<String> weekPlan = [
    'Früh',
    'Früh',
    'Spät',
    'Spät',
    'Nacht',
    'Frei',
    'Frei',
  ];

  ShiftFitPlan get plan => ShiftFitPlan.from(
    shift: selectedShift,
    energy: selectedEnergy,
    stress: selectedStress,
  );

  void _addWater(int ml) {
    setState(() => dailyWaterMl = (dailyWaterMl + ml).clamp(0, 15000));
  }

  void _resetWater() {
    setState(() => dailyWaterMl = 0);
  }

  Future<void> _logSleep() async {
    final entry = await showSleepLogSheet(context, initial: lastSleep);
    if (entry != null && mounted) {
      setState(() => lastSleep = entry);
    }
  }

  void _toggleBlock(String id) {
    final next = {...completedBlockIds};
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    final allDone = plan.blocks.isNotEmpty &&
        plan.blocks.asMap().entries.every(
              (e) => next.contains('${e.key + 1}:${e.value.title}'),
            );

    setState(() {
      if (allDone) {
        workoutStreak += 1;
        completedBlockIds = <String>{};
      } else {
        completedBlockIds = next;
      }
    });

    if (allDone) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Plan abgehakt · Streak: $workoutStreak')),
      );
    }
  }

  void _addResultToDailyTotal(MealAnalysisResult result) {
    setState(() {
      dailyConsumedKcal += result.caloriesKcal;
      macroProgress = macroProgress.add(result);
      _rememberFavorite(result);
    });
  }

  void _adjustDailyTotalDelta(int delta) {
    setState(() {
      dailyConsumedKcal = (dailyConsumedKcal + delta).clamp(0, 99999);
    });
  }

  void _rememberFavorite(MealAnalysisResult result) {
    final id = FavoriteMeal.idFor(result);
    final entry = FavoriteMeal(id: id, result: result, addedAt: DateTime.now());
    favorites = [entry, ...favorites.where((f) => f.id != id)].take(5).toList();
  }

  void _removeFavorite(String id) {
    setState(() {
      favorites = favorites.where((f) => f.id != id).toList();
    });
  }

  Future<void> _openSettings() async {
    final result = await showSettingsSheet(context, profile: profile);
    if (result == null || !mounted) return;
    setState(() {
      profile = result.profile;
      if (result.resetDay) {
        dailyConsumedKcal = 0;
        dailyWaterMl = 0;
        macroProgress = MacroProgress.empty;
        completedBlockIds = <String>{};
      }
    });
    if (result.resetDay) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tagesdaten zurückgesetzt.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      bottomNavigationBar: ShiftFitBottomNav(
        selectedIndex: selectedTab,
        onSelected: (index) => setState(() => selectedTab = index),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          key: ValueKey('tab-scroll-$selectedTab'),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: buildSelectedScreen(),
        ),
      ),
    );
  }

  Widget buildSelectedScreen() {
    return switch (selectedTab) {
      1 => WeekPlannerScreen(
        plan: plan,
        weekPlan: weekPlan,
        onShiftChanged: (dayIndex, shift) {
          setState(() => weekPlan[dayIndex] = shift);
        },
        onSettingsPressed: _openSettings,
      ),
      2 => TrendsScreen(
        plan: plan,
        weekPlan: weekPlan,
        dailyWaterMl: dailyWaterMl,
        waterGoalMl: profile.dailyWaterGoalMl,
        lastSleep: lastSleep,
        sleepGoalMinutes: profile.dailySleepGoalMinutes,
        workoutStreak: workoutStreak,
        completedTodayCount: completedBlockIds.length,
        totalBlocksToday: plan.blocks.length,
        onSettingsPressed: _openSettings,
      ),
      3 => MealAnalysisScreen(
        analyzer: widget.mealAnalyzer,
        productService: widget.productService,
        photoInput: widget.photoInput,
        dailyConsumedKcal: dailyConsumedKcal,
        macroProgress: macroProgress,
        profile: profile,
        favorites: favorites,
        onAddResultToDailyTotal: _addResultToDailyTotal,
        onAdjustDailyKcal: _adjustDailyTotalDelta,
        onRemoveFavorite: _removeFavorite,
      ),
      _ => TodayDashboard(
        selectedShift: selectedShift,
        selectedEnergy: selectedEnergy,
        selectedStress: selectedStress,
        plan: plan,
        onShiftSelected: (value) => setState(() => selectedShift = value),
        onEnergySelected: (value) => setState(() => selectedEnergy = value),
        onStressSelected: (value) => setState(() => selectedStress = value),
        dailyWaterMl: dailyWaterMl,
        waterGoalMl: profile.dailyWaterGoalMl,
        onAddWater: _addWater,
        onResetWater: _resetWater,
        lastSleep: lastSleep,
        sleepGoalMinutes: profile.dailySleepGoalMinutes,
        onLogSleep: _logSleep,
        completedBlockIds: completedBlockIds,
        onToggleBlock: _toggleBlock,
        workoutStreak: workoutStreak,
        onSettingsPressed: _openSettings,
      ),
    };
  }
}

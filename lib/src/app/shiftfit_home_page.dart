import 'package:flutter/material.dart';

import '../models/caffeine_entry.dart';
import '../models/daily_mood.dart';
import '../models/favorite_meal.dart';
import '../models/habit.dart';
import '../models/lifetime_stats.dart';
import '../models/macro_progress.dart';
import '../models/meal_analysis_result.dart';
import '../models/shift_fit_plan.dart';
import '../models/sleep_entry.dart';
import '../models/user_profile.dart';
import '../models/weight_log.dart';
import '../services/health_service.dart';
import '../services/meal_analyzer.dart';
import '../services/meal_photo_input.dart';
import '../services/open_food_facts_product_service.dart';
import '../screens/meal_analysis_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/today_dashboard.dart';
import '../screens/trends_screen.dart';
import '../screens/week_planner_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/app_shell/shiftfit_bottom_nav.dart';
import '../widgets/shared/quick_add_sheet.dart';
import '../widgets/shared/settings_sheet.dart';
import '../widgets/today/habits_card.dart';
import '../widgets/today/mood_card.dart';
import '../widgets/today/wellness_widgets.dart';

class ShiftFitHomePage extends StatefulWidget {
  ShiftFitHomePage({
    super.key,
    this.mealAnalyzer,
    this.productService,
    this.photoInput,
    this.healthService,
  });

  final MealAnalyzer? mealAnalyzer;
  final ProductLookupService? productService;
  final MealPhotoInput? photoInput;
  final HealthService? healthService;

  @override
  State<ShiftFitHomePage> createState() => _ShiftFitHomePageState();
}

class _ShiftFitHomePageState extends State<ShiftFitHomePage> {
  String selectedShift = 'Muskelaufbau';
  String selectedEnergy = 'Normal';
  String selectedStress = 'Mittel';
  int selectedTab = 0;
  int dailyConsumedKcal = 0;
  int dailyWaterMl = 0;
  int dailySteps = 0;
  UserProfile profile = const UserProfile();
  MacroProgress macroProgress = MacroProgress.empty;
  SleepEntry? lastSleep;
  Set<String> completedBlockIds = <String>{};
  int workoutStreak = 0;
  List<FavoriteMeal> favorites = <FavoriteMeal>[];
  CaffeineDay caffeineDay = const CaffeineDay();
  DailyMood mood = DailyMood.empty;
  HabitState habits = const HabitState();
  WeightLog weightLog = const WeightLog();
  HealthAuthState healthAuthState = HealthAuthState.unknown;
  DateTime? healthLastFetch;
  bool healthSyncing = false;
  LifetimeStats lifetimeStats = LifetimeStats();
  String userName = 'Moritz';
  final ValueNotifier<int> _profileRefresh = ValueNotifier<int>(0);

  int get stepsGoal => profile.dailyStepsGoal;

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    _profileRefresh.value++;
  }

  @override
  void dispose() {
    _profileRefresh.dispose();
    super.dispose();
  }

  HealthService get _health =>
      widget.healthService ?? const NoopHealthService();
  final List<String> weekPlan = [
    'Kraft',
    'Muskelaufbau',
    'Ausdauer',
    'Mobility',
    'Kraft',
    'Recovery',
    'Frei',
  ];

  ShiftFitPlan get plan => ShiftFitPlan.from(
    shift: selectedShift,
    energy: selectedEnergy,
    stress: selectedStress,
  );

  @override
  void initState() {
    super.initState();
    if (widget.healthService != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _connectHealth());
    }
  }

  Future<void> _connectHealth() async {
    if (!mounted) return;
    setState(() => healthSyncing = true);
    final state = await _health.requestAuthorization();
    if (!mounted) return;
    setState(() => healthAuthState = state);
    if (state == HealthAuthState.granted) {
      await _refreshHealthSteps();
    } else {
      setState(() => healthSyncing = false);
    }
  }

  Future<void> _refreshHealthSteps() async {
    if (!mounted) return;
    setState(() => healthSyncing = true);
    final snapshot = await _health.readSnapshot();
    if (!mounted) return;
    setState(() {
      healthSyncing = false;
      if (snapshot != null) {
        dailySteps = snapshot.stepsToday;
        healthLastFetch = snapshot.fetchedAt;
        healthAuthState = HealthAuthState.granted;
      }
    });
  }

  void _addWater(int ml) {
    setState(() {
      dailyWaterMl = (dailyWaterMl + ml).clamp(0, 15000);
      if (ml > 0) lifetimeStats = lifetimeStats.addWater(ml);
    });
  }

  void _toggleHabit(String id) {
    setState(() => habits = habits.toggle(id));
  }

  void _logWeight(double kg) {
    setState(() {
      weightLog = weightLog.add(kg);
      lifetimeStats = lifetimeStats.incrementWeightLogs();
    });
  }

  Future<void> _openQuickAdd() async {
    final result = await showQuickAddSheet(context);
    if (result == null || !mounted) return;
    switch (result.kind) {
      case QuickAddKind.water:
        if (result.amount != null) _addWater(result.amount!);
        break;
      case QuickAddKind.caffeine:
        if (result.amount != null) _addCaffeine(result.amount!);
        break;
      case QuickAddKind.steps:
        if (result.amount != null) _addSteps(result.amount!);
        break;
      case QuickAddKind.sleep:
        _logSleep();
        break;
    }
  }

  void _resetWater() {
    setState(() => dailyWaterMl = 0);
  }

  void _addCaffeine(int mg) {
    setState(() => caffeineDay = caffeineDay.add(mg));
  }

  void _resetCaffeine() {
    setState(() => caffeineDay = caffeineDay.reset());
  }

  void _addSteps(int amount) {
    setState(() {
      dailySteps = (dailySteps + amount).clamp(0, 100000);
      if (amount > 0) lifetimeStats = lifetimeStats.addSteps(amount);
    });
  }

  void _setSteps(int amount) {
    setState(() => dailySteps = amount.clamp(0, 100000));
  }

  void _setMoodScore(int score) {
    setState(() => mood = DailyMood(score: score, note: mood.note));
  }

  Future<void> _editMoodNote() async {
    final result = await showMoodNoteSheet(context, initial: mood.note);
    if (result != null && mounted) {
      setState(() => mood = DailyMood(score: mood.score, note: result));
    }
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
        lifetimeStats = lifetimeStats.incrementWorkouts();
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
      lifetimeStats = lifetimeStats.incrementMeals();
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
        dailySteps = 0;
        macroProgress = MacroProgress.empty;
        completedBlockIds = <String>{};
        caffeineDay = const CaffeineDay();
        mood = DailyMood.empty;
        habits = const HabitState();
      }
    });
    if (result.resetDay) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tagesdaten zurückgesetzt.')),
      );
    }
  }

  void _resetTodayData() {
    setState(() {
      dailyConsumedKcal = 0;
      dailyWaterMl = 0;
      dailySteps = 0;
      macroProgress = MacroProgress.empty;
      completedBlockIds = <String>{};
      caffeineDay = const CaffeineDay();
      mood = DailyMood.empty;
      habits = const HabitState();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tagesdaten zurückgesetzt.')),
    );
  }

  Future<void> _openProfile() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AnimatedBuilder(
          animation: _profileRefresh,
          builder: (_, __) => ProfileScreen(
            name: userName,
            profile: profile,
            weightLog: weightLog,
            stats: lifetimeStats,
            plan: plan,
            weekPlan: weekPlan,
            workoutStreak: workoutStreak,
            dailyConsumedKcal: dailyConsumedKcal,
            dailyWaterMl: dailyWaterMl,
            dailySteps: dailySteps,
            lastSleep: lastSleep,
            healthAuthState: healthAuthState,
            healthLastFetch: healthLastFetch,
            favoritesCount: favorites.length,
            onLogWeight: _logWeight,
            onEditProfile: _openSettings,
            onResetDay: _resetTodayData,
            onConnectHealth: _connectHealth,
            onRefreshHealth: _refreshHealthSteps,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      bottomNavigationBar: ShiftFitBottomNav(
        selectedIndex: selectedTab,
        onSelected: (index) => setState(() => selectedTab = index),
      ),
      floatingActionButton: FloatingActionButton(
        key: const ValueKey('quick-add-fab'),
        onPressed: _openQuickAdd,
        backgroundColor: lime,
        foregroundColor: bg,
        tooltip: 'Schnell loggen',
        child: const Icon(Icons.bolt_rounded),
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
        onProfilePressed: _openProfile,
        profileInitial: _profileInitial,
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
        dailySteps: dailySteps,
        stepsGoal: stepsGoal,
        dailyConsumedKcal: dailyConsumedKcal,
        kcalGoal: profile.dailyKcalGoal,
        onSettingsPressed: _openSettings,
        onProfilePressed: _openProfile,
        profileInitial: _profileInitial,
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
        dailyConsumedKcal: dailyConsumedKcal,
        kcalGoal: profile.dailyKcalGoal,
        dailyWaterMl: dailyWaterMl,
        waterGoalMl: profile.dailyWaterGoalMl,
        dailySteps: dailySteps,
        stepsGoal: stepsGoal,
        lastSleep: lastSleep,
        sleepGoalMinutes: profile.dailySleepGoalMinutes,
        completedBlockIds: completedBlockIds,
        onToggleBlock: _toggleBlock,
        workoutStreak: workoutStreak,
        healthAuthState: healthAuthState,
        healthLastFetch: healthLastFetch,
        onConnectHealth: _connectHealth,
        onRefreshHealth: _refreshHealthSteps,
        onSettingsPressed: _openSettings,
        onProfilePressed: _openProfile,
        profileInitial: _profileInitial,
      ),
    };
  }

  String get _profileInitial {
    final parts = userName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'S';
    return parts.first.substring(0, 1).toUpperCase();
  }
}

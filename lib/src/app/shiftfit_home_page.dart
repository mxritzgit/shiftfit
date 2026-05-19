import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';

import '../models/caffeine_entry.dart';
import '../models/daily_mood.dart';
import '../models/favorite_meal.dart';
import '../models/habit.dart';
import '../models/lifetime_stats.dart';
import '../models/logged_meal.dart';
import '../models/macro_progress.dart';
import '../models/meal_analysis_result.dart';
import '../models/shift_fit_plan.dart';
import '../models/sleep_entry.dart';
import '../models/user_profile.dart';
import '../models/weight_log.dart';
import '../services/daily_log_sync.dart';
import '../services/fitpilot_sync.dart';
import '../services/health_service.dart';
import '../services/kcal_calculator.dart';
import '../services/meal_analyzer.dart';
import '../services/meal_photo_input.dart';
import '../services/open_food_facts_product_service.dart';
import '../services/uuid.dart';
import '../screens/coach_chat_screen.dart';
import '../screens/meal_analysis_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/recipes_screen.dart';
import '../screens/today_dashboard.dart';
import '../screens/trends_screen.dart';
import '../screens/week_planner_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/app_shell/shiftfit_bottom_nav.dart';
import '../widgets/auth/welcome_screen.dart';
import '../widgets/shared/settings_sheet.dart';
import '../widgets/today/mood_card.dart';
import '../widgets/today/wellness_widgets.dart';

class ShiftFitHomePage extends StatefulWidget {
  ShiftFitHomePage({
    super.key,
    this.mealAnalyzer,
    this.productService,
    this.photoInput,
    this.healthService,
    this.initialUserName = 'Moritz',
    this.onSignOut,
    this.sync,
    this.showWelcome = false,
  });

  final MealAnalyzer? mealAnalyzer;
  final ProductLookupService? productService;
  final MealPhotoInput? photoInput;
  final HealthService? healthService;
  final String initialUserName;
  final Future<void> Function()? onSignOut;
  final FitPilotSync? sync;

  /// True nur bei frischem Login/Register in dieser App-Session.
  /// Bei Session-Restore (App-Kaltstart mit gueltigem Token) false -
  /// dann fliegt der User direkt aufs Home ohne Welcome-Phase.
  final bool showWelcome;

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
  DateTime selectedFoodDate = DateUtils.dateOnly(DateTime.now());
  UserProfile profile = const UserProfile();
  MacroProgress macroProgress = MacroProgress.empty;
  SleepEntry? lastSleep;
  Set<String> completedBlockIds = <String>{};
  int workoutStreak = 0;
  List<FavoriteMeal> favorites = <FavoriteMeal>[];
  List<LoggedMeal> loggedMeals = <LoggedMeal>[];
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
  late bool _profileLoaded;
  late bool _welcomeFinished;
  final Completer<void> _profileReadyCompleter = Completer<void>();

  int get stepsGoal => profile.dailyStepsGoal;

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    _profileRefresh.value++;
  }

  @override
  void initState() {
    super.initState();
    userName = widget.initialUserName;
    // Ohne Sync (Preview/Test) ueberspringen wir Boot- und Welcome-Phase
    // direkt - tests pumpen einen Frame und erwarten sofort das Home.
    final hasSync = widget.sync != null;
    _profileLoaded = !hasSync;
    // Im Test/Preview (kein Sync) gehts direkt zum Home. Bei Production
    // wird IMMER ein Splash gezeigt bis Daten geladen sind, damit kein
    // Default-Flash sichtbar wird. Die Welcome-Celebration (Check-Icon
    // + "Willkommen, X") laeuft drinnen nur wenn widget.showWelcome.
    _welcomeFinished = !hasSync;
    if (!hasSync && !_profileReadyCompleter.isCompleted) {
      _profileReadyCompleter.complete();
    }
    if (widget.healthService != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _connectHealth());
    }
    if (hasSync) {
      _bootFromSupabase();
    }
  }

  /// Laedt beim App-Start alle persistierten Daten parallel aus Supabase
  /// und uebernimmt sie in den lokalen State. Einzelne Loads die failen
  /// (Netzwerk, fehlende Zeile) bleiben still und lassen den Default-State
  /// stehen - der naechste Save fixt das automatisch.
  Future<void> _bootFromSupabase() async {
    final sync = widget.sync!;
    final today = DateTime.now();
    final results = await Future.wait<Object?>([
      _safeLoad(() => sync.profile.load()),
      _safeLoad(() => sync.meals.loadLoggedMeals()),
      _safeLoad(() => sync.meals.loadFavorites()),
      _safeLoad(() => sync.dailyLog.loadForDate(today)),
      _safeLoad(() => sync.tracking.loadWeightLog()),
      _safeLoad(() => sync.tracking.loadCaffeineDay(today)),
      _safeLoad(() => sync.tracking.loadLatestSleep()),
    ]);
    if (!mounted) return;
    setState(() {
      final loadedProfile = results[0] as UserProfile?;
      if (loadedProfile != null) profile = loadedProfile;

      final loadedMeals = results[1] as List<LoggedMeal>?;
      if (loadedMeals != null) {
        loggedMeals = loadedMeals;
      }

      final loadedFavorites = results[2] as List<FavoriteMeal>?;
      if (loadedFavorites != null) favorites = loadedFavorites;

      final loadedDailyLog = results[3] as DailyLog?;
      if (loadedDailyLog != null) {
        dailyWaterMl = loadedDailyLog.waterMl;
        if (loadedDailyLog.steps > 0) {
          // HealthKit ueberschreibt das ggf. spaeter via _refreshHealthSteps.
          dailySteps = loadedDailyLog.steps;
        }
        mood = loadedDailyLog.mood;
        habits = loadedDailyLog.habitState;
        completedBlockIds = loadedDailyLog.completedBlockIds;
      }

      final loadedWeightLog = results[4] as WeightLog?;
      if (loadedWeightLog != null) weightLog = loadedWeightLog;

      final loadedCaffeine = results[5] as CaffeineDay?;
      if (loadedCaffeine != null) caffeineDay = loadedCaffeine;

      final loadedSleep = results[6] as SleepEntry?;
      if (loadedSleep != null) lastSleep = loadedSleep;

      dailyConsumedKcal = _consumedKcalForFoodDate(today);
      macroProgress = _macroProgressForFoodDate(today);
      _profileLoaded = true;
    });
    if (!_profileReadyCompleter.isCompleted) {
      _profileReadyCompleter.complete();
    }
  }

  Future<T?> _safeLoad<T>(Future<T?> Function() loader) async {
    try {
      return await loader();
    } catch (e, s) {
      dev.log('FitPilot load failed',
          error: e, stackTrace: s, name: 'fitpilot_sync');
      return null;
    }
  }

  /// Routes Sync-Fehler aus fire-and-forget Futures in eine sichtbare
  /// Snackbar. Frueher haben wir die einfach geschluckt - mit dem
  /// Resultat dass Mahlzeiten "still" verschwanden weil 42501 oder
  /// Netzwerkfehler unsichtbar blieben.
  void _reportSyncError(String operation, Object error) {
    dev.log('$operation failed',
        error: error, name: 'fitpilot_sync');
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.removeCurrentSnackBar();
    final msg = error.toString();
    final short = msg.length > 140 ? '${msg.substring(0, 140)}…' : msg;
    messenger.showSnackBar(SnackBar(
      duration: const Duration(seconds: 4),
      content: Text('Sync ($operation): $short'),
    ));
  }

  /// Sammelt das aktuelle Daily-Log und schickt es debounced an
  /// daily_logs (Tagesziel-State: water_ml, steps, mood, blocks, habits).
  void _queueDailyLogSync() {
    final sync = widget.sync;
    if (sync == null) return;
    sync.dailyLog.queueUpsert(DailyLog(
      date: DateTime.now(),
      waterMl: dailyWaterMl,
      steps: dailySteps,
      moodScore: mood.score,
      moodNote: mood.note,
      completedBlockIds: completedBlockIds,
      completedHabitIds: habits.completedIds,
    ));
  }

  @override
  void dispose() {
    _profileRefresh.dispose();
    widget.sync?.dispose();
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
    _queueDailyLogSync();
  }

  void _toggleHabit(String id) {
    setState(() => habits = habits.toggle(id));
    _queueDailyLogSync();
  }

  void _logWeight(double kg) {
    final ts = DateTime.now();
    setState(() {
      weightLog = weightLog.add(kg);
      lifetimeStats = lifetimeStats.incrementWeightLogs();
    });
    widget.sync?.tracking
        .insertWeight(kg, ts)
        .catchError((e) => _reportSyncError('Gewicht', e));
  }

  void _resetWater() {
    setState(() => dailyWaterMl = 0);
    _queueDailyLogSync();
  }

  void _addCaffeine(int mg) {
    final ts = DateTime.now();
    setState(() => caffeineDay = caffeineDay.add(mg));
    widget.sync?.tracking
        .insertCaffeine(mg, ts)
        .catchError((e) => _reportSyncError('Koffein', e));
  }

  void _resetCaffeine() {
    setState(() => caffeineDay = caffeineDay.reset());
    widget.sync?.tracking
        .resetCaffeineDay(DateTime.now())
        .catchError((e) => _reportSyncError('Koffein-Reset', e));
  }

  void _addSteps(int amount) {
    setState(() {
      dailySteps = (dailySteps + amount).clamp(0, 100000);
      if (amount > 0) lifetimeStats = lifetimeStats.addSteps(amount);
    });
    _queueDailyLogSync();
  }

  void _setSteps(int amount) {
    setState(() => dailySteps = amount.clamp(0, 100000));
    _queueDailyLogSync();
  }

  void _setMoodScore(int score) {
    setState(() => mood = DailyMood(score: score, note: mood.note));
    _queueDailyLogSync();
  }

  Future<void> _editMoodNote() async {
    final result = await showMoodNoteSheet(context, initial: mood.note);
    if (result != null && mounted) {
      setState(() => mood = DailyMood(score: mood.score, note: result));
      _queueDailyLogSync();
    }
  }

  Future<void> _logSleep() async {
    final entry = await showSleepLogSheet(context, initial: lastSleep);
    if (entry != null && mounted) {
      setState(() => lastSleep = entry);
      widget.sync?.tracking
          .upsertSleep(entry)
          .catchError((e) => _reportSyncError('Schlaf', e));
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
    _queueDailyLogSync();

    if (allDone) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Plan abgehakt · Streak: $workoutStreak')),
      );
    }
  }

  bool _isSameFoodDate(DateTime a, DateTime b) {
    return DateUtils.isSameDay(a, b);
  }

  bool get _selectedFoodDateIsToday {
    return _isSameFoodDate(selectedFoodDate, DateTime.now());
  }

  DateTime _timestampForFoodDate(DateTime date) {
    final now = DateTime.now();
    final day = DateUtils.dateOnly(date);
    return DateTime(day.year, day.month, day.day, now.hour, now.minute);
  }

  List<LoggedMeal> _mealsForFoodDate(DateTime date) {
    final day = DateUtils.dateOnly(date);
    return loggedMeals
        .where((meal) => _isSameFoodDate(meal.loggedAt, day))
        .toList(growable: false);
  }

  int _consumedKcalForFoodDate(DateTime date) {
    return _mealsForFoodDate(date).fold<int>(
      0,
      (sum, meal) => sum + meal.result.caloriesKcal,
    );
  }

  MacroProgress _macroProgressForFoodDate(DateTime date) {
    return _mealsForFoodDate(date).fold<MacroProgress>(
      MacroProgress.empty,
      (progress, meal) => progress.add(meal.result),
    );
  }

  MealAnalysisResult _copyResultWithKcal(
    MealAnalysisResult original,
    int caloriesKcal,
  ) {
    return MealAnalysisResult(
      mealName: original.mealName,
      caloriesKcal: caloriesKcal,
      estimatedGrams: original.estimatedGrams,
      kcalPer100G: original.kcalPer100G,
      protein: original.protein,
      carbs: original.carbs,
      fat: original.fat,
      confidence: original.confidence,
      portionNotes: original.portionNotes,
      items: original.items,
      isAdjusted: true,
      sourceLabel: original.sourceLabel,
      barcode: original.barcode,
      brand: original.brand,
    );
  }

  void _addResultToDailyTotal(
    MealAnalysisResult result, {
    MealSlot? slot,
    DateTime? foodDate,
  }) {
    final targetDate = DateUtils.dateOnly(foodDate ?? selectedFoodDate);
    final entry = LoggedMeal(
      id: uuidV4(),
      result: result,
      loggedAt: _timestampForFoodDate(targetDate),
      forcedSlot: slot,
    );
    final targetIsToday = _isSameFoodDate(targetDate, DateTime.now());
    setState(() {
      lifetimeStats = lifetimeStats.incrementMeals();
      _rememberFavorite(result);
      loggedMeals = [entry, ...loggedMeals];
      if (targetIsToday) {
        dailyConsumedKcal = _consumedKcalForFoodDate(DateTime.now());
        macroProgress = _macroProgressForFoodDate(DateTime.now());
      }
    });
    widget.sync?.meals
        .insertLoggedMeal(entry)
        .catchError((e) => _reportSyncError('Mahlzeit', e));
  }

  void _removeLoggedMeal(String id) {
    setState(() {
      loggedMeals = loggedMeals.where((m) => m.id != id).toList();
      if (_selectedFoodDateIsToday) {
        dailyConsumedKcal = _consumedKcalForFoodDate(DateTime.now());
        macroProgress = _macroProgressForFoodDate(DateTime.now());
      }
    });
    widget.sync?.meals
        .deleteLoggedMeal(id)
        .catchError((e) => _reportSyncError('Mahlzeit-Delete', e));
  }

  void _adjustDailyTotalDelta(int delta) {
    LoggedMeal? updated;
    setState(() {
      final index = loggedMeals.indexWhere(
        (meal) => _isSameFoodDate(meal.loggedAt, selectedFoodDate),
      );
      if (index == -1) return;
      final latest = loggedMeals[index];
      final adjustedKcal =
          (latest.result.caloriesKcal + delta).clamp(0, 99999).toInt();
      final nextMeals = [...loggedMeals];
      updated = LoggedMeal(
        id: latest.id,
        loggedAt: latest.loggedAt,
        result: _copyResultWithKcal(latest.result, adjustedKcal),
        forcedSlot: latest.forcedSlot,
      );
      nextMeals[index] = updated!;
      loggedMeals = nextMeals;
      if (_selectedFoodDateIsToday) {
        dailyConsumedKcal = _consumedKcalForFoodDate(DateTime.now());
        macroProgress = _macroProgressForFoodDate(DateTime.now());
      }
    });
    final remoteUpdate = updated;
    if (remoteUpdate != null) {
      widget.sync?.meals
          .updateLoggedMeal(remoteUpdate)
          .catchError((e) => _reportSyncError('Mahlzeit-Update', e));
    }
  }

  void _rememberFavorite(MealAnalysisResult result) {
    final id = FavoriteMeal.idFor(result);
    final entry = FavoriteMeal(id: id, result: result, addedAt: DateTime.now());
    favorites = [entry, ...favorites.where((f) => f.id != id)].take(5).toList();
    widget.sync?.meals
        .upsertFavorite(entry)
        .catchError((e) => _reportSyncError('Favorit', e));
  }

  void _removeFavorite(String id) {
    setState(() {
      favorites = favorites.where((f) => f.id != id).toList();
    });
    widget.sync?.meals
        .deleteFavorite(id)
        .catchError((e) => _reportSyncError('Favorit-Delete', e));
  }

  Future<void> _openSettings() async {
    final result = await showSettingsSheet(context, profile: profile);
    if (result == null || !mounted) return;
    final wasReset = result.resetDay;
    setState(() {
      profile = result.profile;
      if (wasReset) {
        dailyConsumedKcal = 0;
        dailyWaterMl = 0;
        dailySteps = 0;
        macroProgress = MacroProgress.empty;
        completedBlockIds = <String>{};
        caffeineDay = const CaffeineDay();
        mood = DailyMood.empty;
        habits = const HabitState();
        loggedMeals = <LoggedMeal>[];
        selectedFoodDate = DateUtils.dateOnly(DateTime.now());
      }
    });
    // Profil-Save AWAIT damit Fehler sichtbar werden (Snackbar). Vorher
    // wurde der Future weggeschluckt -> User dachte das Speichern haette
    // funktioniert obwohl er still gescheitert ist.
    final sync = widget.sync;
    if (sync != null) {
      try {
        await sync.profile.save(result.profile);
        if (wasReset) {
          await sync.dailyLog.flush();
          _queueDailyLogSync();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profil-Sync: $e')),
          );
        }
      }
    }
    if (wasReset && mounted) {
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
      loggedMeals = <LoggedMeal>[];
      selectedFoodDate = DateUtils.dateOnly(DateTime.now());
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
            onSignOut: widget.onSignOut,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_welcomeFinished) {
      return WelcomeScreen(
        firstName: userName,
        profileReady: _profileReadyCompleter.future,
        celebrateLogin: widget.showWelcome,
        onComplete: () {
          if (mounted) setState(() => _welcomeFinished = true);
        },
      );
    }

    // Tab 3 (Food), Tab 4 (Rezepte) und Tab 5 (Coach) haben eigene
    // scroll-faehige Inhalte + fixierte Eingabe-Bereiche - die brauchen
    // feste Hoehe und keinen aeusseren SingleChildScrollView.
    final fixedHeightTab = selectedTab == 3 || selectedTab == 4 || selectedTab == 5;
    final body = fixedHeightTab
        ? Padding(
            key: ValueKey('tab-fixed-$selectedTab'),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: buildSelectedScreen(),
          )
        : SingleChildScrollView(
            key: ValueKey('tab-scroll-$selectedTab'),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: buildSelectedScreen(),
          );

    return Scaffold(
      backgroundColor: bg,
      bottomNavigationBar: ShiftFitBottomNav(
        selectedIndex: selectedTab,
        onSelected: (index) => setState(() => selectedTab = index),
      ),
      body: SafeArea(child: body),
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
      5 => CoachChatScreen(
        service: widget.sync?.coachChat,
        userName: userName,
      ),
      3 => MealAnalysisScreen(
        analyzer: widget.mealAnalyzer,
        productService: widget.productService,
        photoInput: widget.photoInput,
        selectedDate: selectedFoodDate,
        onDateSelected: (date) {
          setState(() => selectedFoodDate = DateUtils.dateOnly(date));
        },
        dailyConsumedKcal: _consumedKcalForFoodDate(selectedFoodDate),
        macroProgress: _macroProgressForFoodDate(selectedFoodDate),
        profile: profile,
        favorites: favorites,
        loggedMeals: _mealsForFoodDate(selectedFoodDate),
        burnedKcal: _selectedFoodDateIsToday
            ? estimateKcalBurnedFromSteps(
                steps: dailySteps,
                weightKg: profile.weightKg,
                heightCm: profile.heightCm,
                sex: profile.sex,
              )
            : 0,
        onAddMeal: (result, slot) =>
            _addResultToDailyTotal(result, slot: slot),
        onAdjustDailyKcal: _adjustDailyTotalDelta,
        onRemoveFavorite: _removeFavorite,
        onRemoveMeal: _removeLoggedMeal,
      ),
      4 => RecipesScreen(
        onAddMeal: (result, slot) => _addResultToDailyTotal(
          result,
          slot: slot,
          foodDate: DateTime.now(),
        ),
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


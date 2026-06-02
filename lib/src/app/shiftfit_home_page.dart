import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
import '../screens/onboarding_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/recipes_screen.dart';
import '../screens/today_dashboard.dart';
import '../screens/trends_screen.dart';
import '../screens/week_planner_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/app_shell/shiftfit_bottom_nav.dart';
import '../widgets/auth/welcome_screen.dart';
import '../widgets/common/app_snack.dart';
import '../widgets/common/lively.dart';
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

class _ShiftFitHomePageState extends State<ShiftFitHomePage>
    with WidgetsBindingObserver {
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
  // Tageswert: bleibt true sobald der Plan einmal voll abgehakt wurde — das
  // robuste Signal fuer Streak/History (completedBlockIds wird bei Abschluss
  // geleert). Wird in daily_logs.workout_completed persistiert.
  bool workoutCompletedToday = false;
  // Letzte ~30 Tage daily_logs fuer den Trends-Verlauf (echte History statt
  // Demo-Daten). Beim Boot via DailyLogSync.loadRange befuellt.
  List<DailyLog> _trendsHistory = const <DailyLog>[];
  // Debounce für den Lifetime-Stats-Upsert (mehrere Quick-Logs → 1 Write).
  Timer? _statsSaveDebounce;
  String userName = 'Moritz';
  final ValueNotifier<int> _profileRefresh = ValueNotifier<int>(0);
  late bool _profileLoaded;
  late bool _welcomeFinished;
  // Lokales Flag, damit der User nach Abschluss sofort weiterkommt — auch
  // falls der Supabase-Save kurz hakt (das onboardingCompleted-Flag aus dem
  // berechneten Profil greift parallel).
  bool _onboardingDone = false;
  final Completer<void> _profileReadyCompleter = Completer<void>();

  int get stepsGoal => profile.dailyStepsGoal;

  /// Kompakter Tages-/Profil-Snapshot für den AI-Coach, damit er konkret statt
  /// generisch beraten kann (z.B. „dir fehlen heute 38 g Protein").
  String get _coachContext {
    final p = profile;
    final remKcal = p.dailyKcalGoal - dailyConsumedKcal;
    final remProt = (p.proteinGoalG - macroProgress.proteinG).round();
    final remCarbs = (p.carbsGoalG - macroProgress.carbsG).round();
    final remFat = (p.fatGoalG - macroProgress.fatG).round();
    return [
      'Körpergewicht: ${p.weightKg} kg (Ziel ${p.targetWeightKg} kg).',
      'Heute gegessen: $dailyConsumedKcal von ${p.dailyKcalGoal} kcal '
          '(noch $remKcal kcal übrig).',
      'Makros heute noch offen: Protein $remProt g, Kohlenhydrate $remCarbs g, '
          'Fett $remFat g.',
      'Aktueller Workout-Streak: $workoutStreak Tage.',
    ].join(' ');
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    _profileRefresh.value++;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
      _safeLoad(() => sync.lifetimeStats.load()),
      _safeLoad(() => sync.weeklyPlan.load()),
      _safeLoad(() => sync.dailyLog
          .loadRange(today.subtract(const Duration(days: 29)), today)),
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
        workoutCompletedToday = loadedDailyLog.workoutCompleted;
      }

      final loadedWeightLog = results[4] as WeightLog?;
      if (loadedWeightLog != null) weightLog = loadedWeightLog;

      final loadedCaffeine = results[5] as CaffeineDay?;
      if (loadedCaffeine != null) caffeineDay = loadedCaffeine;

      final loadedSleep = results[6] as SleepEntry?;
      if (loadedSleep != null) lastSleep = loadedSleep;

      final loadedStats = results[7] as LifetimeStats?;
      if (loadedStats != null) {
        lifetimeStats = loadedStats;
        // Durabler Streak aus der persistierten Zeile (vorher in-memory only).
        workoutStreak = loadedStats.currentStreak;
      }

      final loadedWeek = results[8] as List<String>?;
      if (loadedWeek != null && loadedWeek.length == 7) {
        // weekPlan ist eine final List → in-place ersetzen statt neu zuweisen.
        weekPlan
          ..clear()
          ..addAll(loadedWeek);
      }

      final loadedHistory = results[9] as List<DailyLog>?;
      if (loadedHistory != null) _trendsHistory = loadedHistory;

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
    final msg = error.toString();
    final short = msg.length > 140 ? '${msg.substring(0, 140)}…' : msg;
    showAppSnack(
      context,
      'Sync ($operation): $short',
      icon: Icons.error_outline_rounded,
      accent: danger,
      duration: kSnackError,
    );
  }

  /// Fire-and-forget Sync-Write MIT Rollback: schlägt der Write fehl, wird der
  /// Fehler sichtbar gemeldet UND der optimistische lokale State via [restore]
  /// zurückgerollt — sonst driften lokal und Remote auseinander (beim nächsten
  /// Kaltstart überschreibt _bootFromSupabase den lokalen Stand mit dem Remote).
  void _syncWithRollback(
    String operation,
    Future<void>? future,
    VoidCallback restore,
  ) {
    future?.catchError((Object e) {
      _reportSyncError(operation, e);
      if (mounted) setState(restore);
    });
  }

  /// Zeigt eine Undo-Snackbar nach einer Löschung; [onUndo] stellt den Eintrag
  /// wieder her (lokal + Remote). Vereinheitlicht destruktive Aktionen.
  void _showUndoSnackBar(String label, VoidCallback onUndo) {
    if (!mounted) return;
    showAppSnack(
      context,
      label,
      icon: Icons.delete_outline_rounded,
      accent: danger,
      action: SnackBarAction(label: 'Rückgängig', onPressed: onUndo),
    );
  }

  /// DSGVO Art. 17: löscht Konto + alle Daten serverseitig (RPC), dann ausloggen.
  /// Bei Fehler NICHT ausloggen, damit der User es erneut versuchen kann.
  Future<void> _deleteAccount() async {
    try {
      await widget.sync?.deleteAccount();
    } catch (e) {
      if (mounted) _reportSyncError('Konto-Löschung', e);
      return;
    }
    await widget.onSignOut?.call();
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
      workoutCompleted: workoutCompletedToday,
    ));
  }

  /// Persistiert die kumulierten Lebenszeit-Statistiken (inkl. Streak) nach
  /// Supabase — debounced (600ms), damit eine Serie schneller Quick-Logs
  /// (mehrere +Wasser/+Schritte-Taps) zu EINEM Upsert zusammenläuft (analog zu
  /// DailyLogSync.queueUpsert). Fehler landen sichtbar in einer Snackbar.
  void _saveLifetimeStats() {
    if (widget.sync == null) return;
    _statsSaveDebounce?.cancel();
    _statsSaveDebounce = Timer(const Duration(milliseconds: 600), () {
      widget.sync?.lifetimeStats
          .save(lifetimeStats)
          .catchError((Object e) => _reportSyncError('Statistik', e));
    });
  }

  /// Persistiert den 7-Tage-Wochenplan nach Supabase (fire-and-forget).
  void _saveWeeklyPlan() {
    widget.sync?.weeklyPlan
        .save(weekPlan)
        .catchError((Object e) => _reportSyncError('Wochenplan', e));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _statsSaveDebounce?.cancel();
    _profileRefresh.dispose();
    widget.sync?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // App geht in den Hintergrund / wird beendet: ausstehende debounced Writes
    // (DailyLog 400ms, LifetimeStats 600ms) sofort flushen, damit ein Kill im
    // Debounce-Fenster keine Quick-Logs (Wasser/Schritte/Mood/Streak) verliert.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _flushPendingWrites();
    }
  }

  /// Schreibt ausstehende debounced Writes sofort weg (kein Warten auf den
  /// Timer mehr). Wird beim App-Backgrounding/-Beenden aufgerufen.
  void _flushPendingWrites() {
    final sync = widget.sync;
    if (sync == null) return;
    if (_statsSaveDebounce?.isActive ?? false) {
      _statsSaveDebounce!.cancel();
      sync.lifetimeStats
          .save(lifetimeStats)
          .catchError((Object e) => _reportSyncError('Statistik', e));
    }
    sync.dailyLog.flush();
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
    HapticFeedback.selectionClick();
    setState(() {
      dailyWaterMl = (dailyWaterMl + ml).clamp(0, 15000);
      if (ml > 0) lifetimeStats = lifetimeStats.addWater(ml);
    });
    _queueDailyLogSync();
    _saveLifetimeStats();
  }

  void _toggleHabit(String id) {
    HapticFeedback.selectionClick();
    setState(() => habits = habits.toggle(id));
    _queueDailyLogSync();
  }

  void _logWeight(double kg) {
    HapticFeedback.lightImpact();
    final ts = DateTime.now();
    final prevWeightLog = weightLog;
    final prevStats = lifetimeStats;
    setState(() {
      weightLog = weightLog.add(kg);
      lifetimeStats = lifetimeStats.incrementWeightLogs();
    });
    _syncWithRollback('Gewicht', widget.sync?.tracking.insertWeight(kg, ts), () {
      weightLog = prevWeightLog;
      lifetimeStats = prevStats;
    });
    _saveLifetimeStats();
  }

  void _resetWater() {
    setState(() => dailyWaterMl = 0);
    _queueDailyLogSync();
  }

  void _addCaffeine(int mg) {
    final ts = DateTime.now();
    final prev = caffeineDay;
    setState(() => caffeineDay = caffeineDay.add(mg));
    _syncWithRollback(
      'Koffein',
      widget.sync?.tracking.insertCaffeine(mg, ts),
      () => caffeineDay = prev,
    );
  }

  void _resetCaffeine() {
    final prev = caffeineDay;
    setState(() => caffeineDay = caffeineDay.reset());
    _syncWithRollback(
      'Koffein-Reset',
      widget.sync?.tracking.resetCaffeineDay(DateTime.now()),
      () => caffeineDay = prev,
    );
  }

  void _addSteps(int amount) {
    setState(() {
      dailySteps = (dailySteps + amount).clamp(0, 100000);
      if (amount > 0) lifetimeStats = lifetimeStats.addSteps(amount);
    });
    _queueDailyLogSync();
    _saveLifetimeStats();
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
      final prev = lastSleep;
      setState(() => lastSleep = entry);
      _syncWithRollback(
        'Schlaf',
        widget.sync?.tracking.upsertSleep(entry),
        () => lastSleep = prev,
      );
    }
  }

  void _toggleBlock(String id) {
    HapticFeedback.selectionClick();
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

    // Idempotent pro Tag: nur der ERSTE Voll-Abschluss zählt Workout + Streak
    // hoch. Sonst würde erneutes Abhaken (nach dem Block-Reset) den jetzt
    // persistierten lifetimeStats.workoutsCompleted-Zähler aufblähen.
    final bool wasCompletedToday = workoutCompletedToday;
    setState(() {
      if (allDone) {
        if (!wasCompletedToday) {
          // Streak durabel fortschreiben (gestern→+1, heute→idempotent, sonst
          // Reset 1) + Workout-Zähler + Tages-Flag fürs History-Signal.
          lifetimeStats = lifetimeStats
              .incrementWorkouts()
              .recordWorkoutDay(DateTime.now());
          workoutStreak = lifetimeStats.currentStreak;
          workoutCompletedToday = true;
        }
        completedBlockIds = <String>{};
      } else {
        completedBlockIds = next;
      }
    });
    _queueDailyLogSync();

    if (allDone && !wasCompletedToday) {
      _saveLifetimeStats();
      showAppSnack(
        context,
        'Plan abgehakt · Streak: $workoutStreak',
        icon: Icons.local_fire_department_rounded,
        accent: forgeLime,
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
    HapticFeedback.lightImpact();
    final prevMeals = loggedMeals;
    final prevKcal = dailyConsumedKcal;
    final prevMacros = macroProgress;
    final prevStats = lifetimeStats;
    setState(() {
      lifetimeStats = lifetimeStats.incrementMeals();
      _rememberFavorite(result);
      loggedMeals = [entry, ...loggedMeals];
      if (targetIsToday) {
        dailyConsumedKcal = _consumedKcalForFoodDate(DateTime.now());
        macroProgress = _macroProgressForFoodDate(DateTime.now());
      }
    });
    _syncWithRollback(
      'Mahlzeit',
      widget.sync?.meals.insertLoggedMeal(entry),
      () {
        loggedMeals = prevMeals;
        lifetimeStats = prevStats;
        dailyConsumedKcal = prevKcal;
        macroProgress = prevMacros;
      },
    );
    _saveLifetimeStats();
  }

  void _removeLoggedMeal(String id) {
    final matches = loggedMeals.where((m) => m.id == id);
    final removed = matches.isEmpty ? null : matches.first;
    HapticFeedback.lightImpact();
    final prevMeals = loggedMeals;
    final prevKcal = dailyConsumedKcal;
    final prevMacros = macroProgress;
    setState(() {
      loggedMeals = loggedMeals.where((m) => m.id != id).toList();
      if (_selectedFoodDateIsToday) {
        dailyConsumedKcal = _consumedKcalForFoodDate(DateTime.now());
        macroProgress = _macroProgressForFoodDate(DateTime.now());
      }
    });
    _syncWithRollback(
      'Mahlzeit-Delete',
      widget.sync?.meals.deleteLoggedMeal(id),
      () {
        loggedMeals = prevMeals;
        dailyConsumedKcal = prevKcal;
        macroProgress = prevMacros;
      },
    );
    if (removed != null) {
      _showUndoSnackBar('Mahlzeit gelöscht', () => _restoreLoggedMeal(removed));
    }
  }

  /// Stellt eine per Swipe gelöschte Mahlzeit wieder her (lokal + Remote).
  void _restoreLoggedMeal(LoggedMeal meal) {
    if (loggedMeals.any((m) => m.id == meal.id)) return; // schon zurück
    setState(() {
      loggedMeals = [meal, ...loggedMeals];
      if (_selectedFoodDateIsToday) {
        dailyConsumedKcal = _consumedKcalForFoodDate(DateTime.now());
        macroProgress = _macroProgressForFoodDate(DateTime.now());
      }
    });
    _syncWithRollback(
      'Mahlzeit-Restore',
      widget.sync?.meals.insertLoggedMeal(meal),
      () {
        loggedMeals = loggedMeals.where((m) => m.id != meal.id).toList();
        if (_selectedFoodDateIsToday) {
          dailyConsumedKcal = _consumedKcalForFoodDate(DateTime.now());
          macroProgress = _macroProgressForFoodDate(DateTime.now());
        }
      },
    );
  }

  void _adjustDailyTotalDelta(int delta) {
    final prevMeals = loggedMeals;
    final prevKcal = dailyConsumedKcal;
    final prevMacros = macroProgress;
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
      _syncWithRollback(
        'Mahlzeit-Update',
        widget.sync?.meals.updateLoggedMeal(remoteUpdate),
        () {
          loggedMeals = prevMeals;
          dailyConsumedKcal = prevKcal;
          macroProgress = prevMacros;
        },
      );
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
    final matches = favorites.where((f) => f.id == id);
    final removed = matches.isEmpty ? null : matches.first;
    final prev = favorites;
    setState(() {
      favorites = favorites.where((f) => f.id != id).toList();
    });
    _syncWithRollback(
      'Favorit-Delete',
      widget.sync?.meals.deleteFavorite(id),
      () => favorites = prev,
    );
    if (removed != null) {
      _showUndoSnackBar('Favorit entfernt', () => _restoreFavorite(removed));
    }
  }

  void _restoreFavorite(FavoriteMeal fav) {
    if (favorites.any((f) => f.id == fav.id)) return;
    setState(() {
      favorites = [fav, ...favorites].take(5).toList();
    });
    _syncWithRollback(
      'Favorit-Restore',
      widget.sync?.meals.upsertFavorite(fav),
      () => favorites = favorites.where((f) => f.id != fav.id).toList(),
    );
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
        workoutCompletedToday = false;
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
          showAppSnack(context, 'Profil-Sync: $e',
              icon: Icons.error_outline_rounded,
              accent: danger,
              duration: kSnackError);
        }
      }
    }
    if (wasReset && mounted) {
      showAppSnack(context, 'Tagesdaten zurückgesetzt.',
          icon: Icons.restart_alt_rounded, accent: orange);
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
      workoutCompletedToday = false;
      selectedFoodDate = DateUtils.dateOnly(DateTime.now());
    });
    showAppSnack(context, 'Tagesdaten zurückgesetzt.',
        icon: Icons.restart_alt_rounded, accent: orange);
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
            onDeleteAccount:
                widget.sync != null ? _deleteAccount : null,
          ),
        ),
      ),
    );
  }

  /// Onboarding ist Pflicht, sobald ein echter Supabase-Sync existiert und das
  /// Profil noch nicht durchlaufen wurde. Ohne Sync (Test/Preview) nie.
  bool get _needsOnboarding =>
      widget.sync != null && !_onboardingDone && !profile.onboardingCompleted;

  /// Übernimmt das im Onboarding berechnete Profil (Kalorien-/Makro-Ziel +
  /// onboardingCompleted), persistiert es und lässt den User ins Home. Bei
  /// Save-Fehler kommt der User trotzdem rein — der nächste Profil-Save fixt
  /// das Flag, ein Fehler-Snackbar macht das Problem sichtbar.
  Future<void> _completeOnboarding(UserProfile finished) async {
    setState(() {
      profile = finished;
      _onboardingDone = true;
    });
    final sync = widget.sync;
    if (sync == null) return;
    try {
      await sync.profile.save(finished);
    } catch (e) {
      if (mounted) {
        showAppSnack(context, 'Profil-Sync: $e',
            icon: Icons.error_outline_rounded,
            accent: danger,
            duration: kSnackError);
      }
    }
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

    // Verpflichtendes Onboarding: jeder echte User (mit Supabase-Sync) muss es
    // einmal durchlaufen. Im Test/Preview (sync == null) wird es übersprungen,
    // damit die bestehenden Widget-Tests direkt auf dem Home landen.
    if (_needsOnboarding) {
      return OnboardingScreen(
        firstName: userName,
        initialProfile: profile,
        onComplete: _completeOnboarding,
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
      // Food-Tab (3): Eingabe läuft nur über das modale AddMealSheet, das seine
      // Tastatur-Anpassung selbst macht (Padding bottom: keyboardInset). Würde der
      // Home-Scaffold zusätzlich auf die Tastatur resizen, schöbe sich der Hintergrund
      // sichtbar hinter dem halbtransparenten Barrier (wirkte unprofessionell). Die
      // MealAnalysisScreen hat kein eigenes Inline-Feld, daher hier gefahrlos aus.
      // Andere Tabs behalten das Default-Verhalten (Recipes hat eigenen Scaffold,
      // Coach braucht das Resize für sein Chat-Eingabefeld).
      resizeToAvoidBottomInset: selectedTab != 3,
      bottomNavigationBar: ShiftFitBottomNav(
        selectedIndex: selectedTab,
        onSelected: (index) => setState(() => selectedTab = index),
      ),
      // Sanfter Auftritt pro Tab-Wechsel — Key auf den Tab gepinnt, damit der
      // Effekt bei jedem Wechsel (und beim ersten Anzeigen) erneut abspielt.
      body: SafeArea(
        child: LivelyEntrance(
          key: ValueKey('lively-tab-$selectedTab'),
          child: body,
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
          _saveWeeklyPlan();
        },
        onSavePlan: widget.sync == null ? null : _saveWeeklyPlan,
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
        history: _trendsHistory,
        onSettingsPressed: _openSettings,
        onProfilePressed: _openProfile,
        profileInitial: _profileInitial,
      ),
      5 => CoachChatScreen(
        service: widget.sync?.coachChat,
        userName: userName,
        userContext: widget.sync != null ? _coachContext : null,
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
        // Restmakros des Tages (Ziel − verbraucht) → „Passt zu deinem Ziel".
        remainingMacros: MacroProgress(
          proteinG: (profile.proteinGoalG - macroProgress.proteinG)
              .clamp(0.0, double.infinity)
              .toDouble(),
          carbsG: (profile.carbsGoalG - macroProgress.carbsG)
              .clamp(0.0, double.infinity)
              .toDouble(),
          fatG: (profile.fatGoalG - macroProgress.fatG)
              .clamp(0.0, double.infinity)
              .toDouble(),
          kcal: (profile.dailyKcalGoal - macroProgress.kcal)
              .clamp(0, 1 << 30)
              .toInt(),
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
        caffeineDay: caffeineDay,
        mood: mood,
        habits: habits,
        weightLog: weightLog,
        onAddWater: _addWater,
        onSetSteps: _setSteps,
        onLogSleep: _logSleep,
        onMoodScore: _setMoodScore,
        onEditMoodNote: _editMoodNote,
        onToggleHabit: _toggleHabit,
        onAddCaffeine: _addCaffeine,
        onResetCaffeine: _resetCaffeine,
        onLogWeight: _logWeight,
        onOpenTraining: () => setState(() => selectedTab = 1),
        onOpenFood: () => setState(() => selectedTab = 3),
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


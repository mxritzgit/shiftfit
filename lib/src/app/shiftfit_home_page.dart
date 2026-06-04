import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/caffeine_entry.dart';
import '../models/daily_mood.dart';
import '../models/favorite_meal.dart';
import '../models/fitness_recipe.dart';
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
import '../services/local_cache.dart';
import '../services/meal_analyzer.dart';
import '../services/meal_photo_input.dart';
import '../services/meal_totals.dart' as totals;
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
    this.debugCache,
  });

  final MealAnalyzer? mealAnalyzer;
  final ProductLookupService? productService;
  final MealPhotoInput? photoInput;
  final HealthService? healthService;
  final String initialUserName;
  final Future<void> Function()? onSignOut;
  final FitPilotSync? sync;

  /// Test-Seam (DATA-3): erlaubt es, den durablen Cache direkt zu injizieren,
  /// statt ihn ueber den SharedPreferences-Channel + auth.currentUser.id zu
  /// bauen. So laesst sich der Clobber-Guard/Hydration-Pfad deterministisch
  /// testen, ohne eine echte Supabase-Session zu stellen. In Production immer
  /// null — dann baut [_hydrateThenBoot] den echten Cache.
  @visibleForTesting
  final LocalCache? debugCache;

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
  // Beim Boot aus public.user_recipes geladene Eigen-Rezepte. Wird an die
  // RecipesScreen als Anfangsstand uebergeben (PROD-2), damit selbst angelegte
  // Rezepte einen Neustart ueberleben.
  List<FitnessRecipe> _userRecipes = const <FitnessRecipe>[];
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
  // Debounce für den Lifetime-Stats-Write (mehrere Quick-Logs → 1 RPC-Call).
  Timer? _statsSaveDebounce;
  // Ausstehende, noch nicht persistierte Lifetime-Stats-DELTAS. Quick-Logs
  // (Wasser/Schritte/Mahlzeit/Gewicht) addieren hier auf und werden gesammelt
  // als EIN atomarer increment_lifetime_stats-RPC geflusht. So zaehlt ein
  // Flush-Retry nicht doppelt: die Deltas werden beim Start des Flushes
  // genullt und nur bei Fehler wieder zurueckgelegt.
  int _pendingWaterDelta = 0;
  int _pendingStepsDelta = 0;
  int _pendingMealsDelta = 0;
  int _pendingWeightLogsDelta = 0;
  // Verhindert ueberlappende Flushes (Debounce-Timer + manueller App-Pause-
  // Flush koennten sonst denselben Delta-Stand doppelt rausschicken).
  bool _statsFlushInFlight = false;
  String userName = 'Moritz';
  final ValueNotifier<int> _profileRefresh = ValueNotifier<int>(0);
  late bool _welcomeFinished;
  // Lokales Flag, damit der User nach Abschluss sofort weiterkommt — auch
  // falls der Supabase-Save kurz hakt (das onboardingCompleted-Flag aus dem
  // berechneten Profil greift parallel).
  bool _onboardingDone = false;
  final Completer<void> _profileReadyCompleter = Completer<void>();

  // DATA-3: durabler Write-Through-Cache (SharedPreferences/JSON) fuer Profil,
  // heutiges daily_logs und lifetime_stats. Wird beim Boot asynchron gebaut
  // (kann null bleiben, wenn der SharedPreferences-Channel fehlt — dann laeuft
  // die App schlicht ohne Cache). Jede persistierte Mutation schreibt parallel
  // hier rein; ein Kaltstart hydratisiert ZUERST von hier.
  LocalCache? _cache;

  // Clobber-Guard (DATA-3): bleibt false, solange das in-memory [profile] noch
  // auf den nackten Ctor-Defaults (78 kg / 178 cm) steht. Wird true, sobald das
  // Profil aus einer ECHTEN Quelle stammt — Server-Load, Cache-Hydration ODER
  // frisch im Onboarding eingegeben. NUR dann darf ein Profil-Save die
  // Server-Zeile ueberschreiben; sonst wuerde ein Offline-Kaltstart-Save die
  // echten Werte mit 78/178 plattmachen.
  bool _hydratedFromRealSource = false;

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
      // ZUERST aus dem durablen Cache hydratisieren (letzter bekannter Stand,
      // auch offline), DANN den Netz-Boot starten. So sieht ein Kaltstart ohne
      // Netz die echten letzten Werte statt der 78/178-Defaults; der Netz-Boot
      // ueberschreibt das danach mit der Server-Wahrheit, falls erreichbar.
      unawaited(_hydrateThenBoot());
    }
  }

  /// Cache aufbauen + hydratisieren, dann erst den Netz-Boot starten. Die
  /// Reihenfolge ist wichtig: der Cache-Stand muss VOR dem Server-Load im State
  /// liegen, damit ein offline (oder langsamer) Boot nicht kurz die Defaults
  /// zeigt und ein Profil-Save schon vor dem Server-Load erlaubt ist (gegen die
  /// gecachten, echten Werte — nicht gegen 78/178).
  Future<void> _hydrateThenBoot() async {
    final sync = widget.sync;
    if (sync == null) return;
    if (widget.debugCache != null) {
      // Test-Seam: injizierter Cache, kein Plugin/Session-Lookup.
      _cache = widget.debugCache;
    } else {
      // Cache pro auth.users.id keyn (SharedPreferences ist global). Faellt der
      // User-Id-Lookup aus (z.B. Session-Edge-Case), bleibt _cache null und die
      // App laeuft schlicht ohne durablen Cache weiter.
      final userId = sync.client.auth.currentUser?.id;
      if (userId != null && userId.isNotEmpty) {
        _cache = await LocalCache.create(userId);
      }
    }
    if (_cache != null) {
      await _hydrateFromCache();
    }
    await _bootFromSupabase();
  }

  /// Liest Profil / heutiges daily_logs / lifetime_stats aus dem durablen Cache
  /// und uebernimmt sie in den State, BEVOR das Netz antwortet. Jeder Treffer
  /// markiert die Daten als ECHTE Quelle ([_hydratedFromRealSource]) — der
  /// nachfolgende Netz-Boot ueberschreibt sie ggf. mit der Server-Wahrheit.
  Future<void> _hydrateFromCache() async {
    final cache = _cache;
    if (cache == null) return;
    final today = DateTime.now();
    UserProfile? cachedProfile;
    DailyLog? cachedDaily;
    LifetimeStats? cachedStats;
    try {
      cachedProfile = await cache.readProfile();
      cachedDaily = await cache.readDailyLog(today);
      cachedStats = await cache.readLifetimeStats();
    } catch (e, s) {
      dev.log('LocalCache hydrate failed', error: e, stackTrace: s,
          name: 'local_cache');
    }
    if (!mounted) return;
    if (cachedProfile == null && cachedDaily == null && cachedStats == null) {
      return;
    }
    setState(() {
      if (cachedProfile != null) {
        profile = cachedProfile;
        // Gecachtes Profil zaehlt als echte Quelle: ein Save danach darf die
        // Server-Zeile mit DIESEN Werten aktualisieren (nicht mit 78/178).
        _hydratedFromRealSource = true;
      }
      if (cachedDaily != null) {
        dailyWaterMl = cachedDaily.waterMl;
        if (cachedDaily.steps > 0) dailySteps = cachedDaily.steps;
        mood = cachedDaily.mood;
        habits = cachedDaily.habitState;
        completedBlockIds = cachedDaily.completedBlockIds;
        workoutCompletedToday = cachedDaily.workoutCompleted;
      }
      if (cachedStats != null) {
        lifetimeStats = cachedStats;
        workoutStreak = cachedStats.currentStreak;
      }
      dailyConsumedKcal = _consumedKcalForFoodDate(today);
      macroProgress = _macroProgressForFoodDate(today);
    });
  }

  /// Laedt beim App-Start alle persistierten Daten parallel aus Supabase
  /// und uebernimmt sie in den lokalen State. Einzelne Loads die failen
  /// (Netzwerk, fehlende Zeile) bleiben still und lassen den Default-State
  /// stehen - der naechste Save fixt das automatisch.
  Future<void> _bootFromSupabase() async {
    final sync = widget.sync!;
    // daily_logs-Schreibfehler (debounced/fire-and-forget) sichtbar machen UND
    // den Tagesstand vom Server re-syncen (Server-Wahrheit). Hier verdrahtet,
    // weil die Sync-Instanz vor der HomePage existiert.
    sync.dailyLog.onError = _onDailyLogSyncError;
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
      _safeLoad(() => sync.userRecipes.load()),
    ]);
    if (!mounted) return;
    setState(() {
      final loadedProfile = results[0] as UserProfile?;
      if (loadedProfile != null) {
        profile = loadedProfile;
        // Server-Profil ist die staerkste echte Quelle: ab jetzt darf ein Save
        // die Server-Zeile aktualisieren (Clobber-Guard, DATA-3).
        _hydratedFromRealSource = true;
      }

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

      final loadedRecipes = results[10] as List<FitnessRecipe>?;
      if (loadedRecipes != null) _userRecipes = loadedRecipes;

      dailyConsumedKcal = _consumedKcalForFoodDate(today);
      macroProgress = _macroProgressForFoodDate(today);
    });
    // Frisch geladenen Server-Stand in den durablen Cache spiegeln, damit der
    // naechste (evtl. offline) Kaltstart genau diese Werte zeigt.
    unawaited(_writeCacheSnapshot());
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

  /// Behandelt einen fehlgeschlagenen daily_logs-Write (debounced/fire-and-
  /// forget). daily_logs ist Server-Wahrheit: statt den optimistischen lokalen
  /// Stand zu erraten, wird er sichtbar gemeldet UND der heutige Tagesstand
  /// frisch vom Server geladen + lokal re-appliziert. So konvergiert der lokale
  /// Stand nach einem Write-Fehler wieder auf den tatsaechlich persistierten.
  void _onDailyLogSyncError(Object error) {
    _reportSyncError('Tagesziel', error);
    final sync = widget.sync;
    if (sync == null) return;
    final today = DateTime.now();
    // Re-Load fire-and-forget; schlaegt der Re-Load selbst fehl, bleibt der
    // lokale Stand wie er ist (der naechste erfolgreiche Write fixt ihn).
    sync.dailyLog.loadForDate(today).then((loaded) {
      if (!mounted || loaded == null) return;
      setState(() {
        dailyWaterMl = loaded.waterMl;
        if (loaded.steps > 0) {
          // HealthKit ueberschreibt das ggf. spaeter via _refreshHealthSteps.
          dailySteps = loaded.steps;
        }
        mood = loaded.mood;
        habits = loaded.habitState;
        completedBlockIds = loaded.completedBlockIds;
        workoutCompletedToday = loaded.workoutCompleted;
      });
    }).catchError((Object e, StackTrace s) {
      dev.log('Tagesziel Re-Sync fehlgeschlagen',
          error: e, stackTrace: s, name: 'fitpilot_sync');
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
    // Durablen Cache des geloeschten Kontos leeren, damit kein verwaister
    // Profil-/Tages-/Stats-Stand fuer den naechsten Login auf dem Geraet liegt.
    await _cache?.clear();
    await widget.onSignOut?.call();
  }

  /// Sammelt das aktuelle Daily-Log und schickt es debounced an
  /// daily_logs (Tagesziel-State: water_ml, steps, mood, blocks, habits).
  void _queueDailyLogSync() {
    final sync = widget.sync;
    if (sync == null) return;
    final log = DailyLog(
      date: DateTime.now(),
      waterMl: dailyWaterMl,
      steps: dailySteps,
      moodScore: mood.score,
      moodNote: mood.note,
      completedBlockIds: completedBlockIds,
      completedHabitIds: habits.completedIds,
      workoutCompleted: workoutCompletedToday,
    );
    sync.dailyLog.queueUpsert(log);
    // Write-Through: jeder Tages-Mutations-Pfad laeuft hier durch, also ist das
    // der zentrale Ort, um den durablen Cache-Tagesstand mitzuziehen.
    unawaited(_cache?.writeDailyLog(log) ?? Future<void>.value());
  }

  /// Spiegelt den aktuellen in-memory Stand (Profil + heutiges daily_logs +
  /// lifetime_stats) in den durablen Cache. Defensiv: ist kein Cache verfuegbar
  /// (kein Sync / Plugin-Channel fehlt), ist das ein No-Op. Cache-Fehler killen
  /// nie den UI-Pfad (LocalCache schluckt sie intern).
  Future<void> _writeCacheSnapshot() async {
    final cache = _cache;
    if (cache == null) return;
    await cache.writeProfile(profile);
    await cache.writeDailyLog(DailyLog(
      date: DateTime.now(),
      waterMl: dailyWaterMl,
      steps: dailySteps,
      moodScore: mood.score,
      moodNote: mood.note,
      completedBlockIds: completedBlockIds,
      completedHabitIds: habits.completedIds,
      workoutCompleted: workoutCompletedToday,
    ));
    await cache.writeLifetimeStats(lifetimeStats);
  }

  /// Schreibt nur die lifetime_stats in den Cache (nach optimistischem
  /// Increment oder nach Adoption der Server-Zeile). Eigener schmaler Pfad,
  /// damit der Stats-Flush nicht das ganze Snapshot neu schreibt.
  void _cacheLifetimeStats() {
    unawaited(_cache?.writeLifetimeStats(lifetimeStats) ?? Future<void>.value());
  }

  /// Reiht ein Lifetime-Stats-Delta zur debounced Persistenz ein. Die Deltas
  /// werden akkumuliert (mehrere +Wasser/+Schritte-Taps) und nach 600ms als EIN
  /// atomarer increment_lifetime_stats-RPC geflusht (analog zu
  /// DailyLogSync.queueUpsert). Der in-memory lifetimeStats ist bereits
  /// optimistisch hochgezaehlt (Instant-UI); hier wird nur der PERSIST-Pfad
  /// versorgt. workouts werden hier NICHT mitgegeben — die laufen ueber
  /// record_workout_day (zaehlt workouts_completed serverseitig selbst hoch).
  void _queueStatsDelta({
    int water = 0,
    int steps = 0,
    int meals = 0,
    int weightLogs = 0,
  }) {
    if (widget.sync == null) return;
    _pendingWaterDelta += water;
    _pendingStepsDelta += steps;
    _pendingMealsDelta += meals;
    _pendingWeightLogsDelta += weightLogs;
    // Optimistisch aktualisierte lifetimeStats durabel spiegeln (der Aufrufer
    // hat sie vor diesem Aufruf bereits hochgezaehlt). So ueberlebt ein
    // Offline-Quick-Log einen Kaltstart auch ohne erfolgreichen RPC-Flush.
    _cacheLifetimeStats();
    _statsSaveDebounce?.cancel();
    _statsSaveDebounce = Timer(const Duration(milliseconds: 600), () {
      unawaited(_flushStatsDelta());
    });
  }

  /// Flusht die akkumulierten Lifetime-Stats-Deltas in EINEM atomaren RPC und
  /// uebernimmt die zurueckgegebene Server-Zeile als neue in-memory Wahrheit
  /// (ersetzen, nicht erneut addieren). Idempotent gegen Flush-Retries: die
  /// Deltas werden VOR dem Call genullt und nur bei Fehler zurueckgelegt — ein
  /// Retry schickt dasselbe Delta also nicht doppelt. Bei Fehler wird zusaetzlich
  /// der optimistische in-memory Snapshot zurueckgerollt (mirror _syncWithRollback),
  /// damit ein fehlgeschlagener Increment keine aufgeblaehten lokalen Zaehler
  /// hinterlaesst.
  Future<void> _flushStatsDelta() async {
    final sync = widget.sync;
    if (sync == null) return;
    if (_statsFlushInFlight) return; // ueberlappenden Flush vermeiden
    final water = _pendingWaterDelta;
    final steps = _pendingStepsDelta;
    final meals = _pendingMealsDelta;
    final weightLogs = _pendingWeightLogsDelta;
    if (water == 0 && steps == 0 && meals == 0 && weightLogs == 0) return;
    // Deltas konsumieren BEVOR der Call laeuft → ein Retry nach Erfolg schickt
    // kein zweites Mal dasselbe.
    _pendingWaterDelta = 0;
    _pendingStepsDelta = 0;
    _pendingMealsDelta = 0;
    _pendingWeightLogsDelta = 0;
    _statsFlushInFlight = true;
    final prevStats = lifetimeStats;
    try {
      final fresh = await sync.lifetimeStats.increment(
        water: water,
        steps: steps,
        meals: meals,
        weightLogs: weightLogs,
      );
      if (mounted) {
        setState(() {
          // Server-Zeile ist Wahrheit für die Kumulativ-Zaehler; Streak-Felder
          // (current/longest/last) kommen ebenfalls frisch mit — adoptieren.
          lifetimeStats = fresh;
          workoutStreak = fresh.currentStreak;
        });
      }
      // Adoptierte Server-Zeile durabel cachen (ersetzt den optimistischen Stand).
      _cacheLifetimeStats();
    } catch (e) {
      // Delta zurueck in die Queue, damit der naechste Flush es erneut versucht.
      _pendingWaterDelta += water;
      _pendingStepsDelta += steps;
      _pendingMealsDelta += meals;
      _pendingWeightLogsDelta += weightLogs;
      _reportSyncError('Statistik', e);
      // Optimistisches Increment zurueckrollen (Snapshot von vor dem Flush),
      // damit lokal keine aufgeblaehten Zaehler stehen bleiben.
      if (mounted) setState(() => lifetimeStats = prevStats);
    } finally {
      _statsFlushInFlight = false;
    }
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
    // Ausstehende Lifetime-Stats-Deltas sofort als atomaren RPC rausschicken
    // (kein Warten mehr auf den 600ms-Timer).
    _statsSaveDebounce?.cancel();
    _statsSaveDebounce = null;
    unawaited(_flushStatsDelta());
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
    if (ml > 0) _queueStatsDelta(water: ml);
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
    final sync = widget.sync;
    if (sync == null) return;
    // Den weight_logs-Zaehler-Delta erst NACH erfolgreichem Gewichts-Insert
    // einreihen — sonst persistierte der Lifetime-Counter Gewichtseintraege,
    // die gar nicht geschrieben wurden. Bei Insert-Fehler: in-memory Stats +
    // Gewicht zurueckrollen, KEIN Delta einreihen.
    sync.tracking.insertWeight(kg, ts).then((_) {
      _queueStatsDelta(weightLogs: 1);
    }).catchError((Object e) {
      _reportSyncError('Gewicht', e);
      if (mounted) {
        setState(() {
          weightLog = prevWeightLog;
          lifetimeStats = prevStats;
        });
      }
    });
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
    final prevStats = lifetimeStats;
    final prevStreak = workoutStreak;
    setState(() {
      if (allDone) {
        if (!wasCompletedToday) {
          // Optimistisch: Streak fortschreiben (gestern→+1, heute→idempotent,
          // sonst Reset 1) + Workout-Zähler + Tages-Flag fürs History-Signal.
          // Der Server-RPC record_workout_day macht beides atomar und liefert
          // die wahre Zeile zurück (siehe Persist-Pfad unten).
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
    // Optimistisch hochgezaehlte Workouts/Streak durabel spiegeln (der
    // Server-RPC adoptiert spaeter die wahre Zeile und cached erneut).
    if (allDone && !wasCompletedToday) _cacheLifetimeStats();

    if (allDone && !wasCompletedToday) {
      // Persist über den Streak-RPC: record_workout_day schreibt current/longest
      // _streak + last_workout_date persistent fort UND zählt workouts_completed
      // serverseitig +1. Die zurückgegebene Zeile ist die Wahrheit → adoptieren
      // (ersetzen). Bei Fehler: optimistischen Stand zurückrollen.
      final sync = widget.sync;
      if (sync != null) {
        sync.lifetimeStats.recordWorkoutDay(DateTime.now()).then((fresh) {
          if (!mounted) return;
          setState(() {
            lifetimeStats = fresh;
            workoutStreak = fresh.currentStreak;
          });
          _cacheLifetimeStats();
        }).catchError((Object e) {
          _reportSyncError('Workout-Streak', e);
          if (mounted) {
            setState(() {
              lifetimeStats = prevStats;
              workoutStreak = prevStreak;
              workoutCompletedToday = wasCompletedToday;
            });
          }
        });
      }
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

  // Reine Aggregation lebt in services/meal_totals.dart (unit-getestet) — hier
  // nur dünne Wrapper, die den aktuellen loggedMeals-Stand binden.
  List<LoggedMeal> _mealsForFoodDate(DateTime date) =>
      totals.mealsForFoodDate(loggedMeals, date);

  int _consumedKcalForFoodDate(DateTime date) =>
      totals.consumedKcalForFoodDate(loggedMeals, date);

  MacroProgress _macroProgressForFoodDate(DateTime date) =>
      totals.macroProgressForFoodDate(loggedMeals, date);

  /// Loggt [result] in die Tagesbilanz und liefert die vergebene Client-UUID
  /// zurueck. Der Rueckgabewert erlaubt dem Analyse-Sheet, eine NACHTRAEGLICHE
  /// Um-Portionierung gezielt auf GENAU diese geloggte Zeile anzuwenden
  /// (siehe _updateLoggedMealResult) — statt blind einen kcal-Delta auf die
  /// erste Mahlzeit des Tages zu schieben.
  String _addResultToDailyTotal(
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
      _rememberRecent(result);
      loggedMeals = [entry, ...loggedMeals];
      if (targetIsToday) {
        dailyConsumedKcal = _consumedKcalForFoodDate(DateTime.now());
        macroProgress = _macroProgressForFoodDate(DateTime.now());
      }
    });
    final sync = widget.sync;
    if (sync == null) return entry.id;
    // insertLoggedMeal ist ein idempotenter upsert(onConflict:'id') — ein Retry
    // mit derselben Client-UUID schreibt dieselbe Zeile (kein Duplikat-Fehler).
    // Den meals_logged-Zähler-Delta erst NACH erfolgreichem Insert einreihen,
    // damit der Lifetime-Counter keine nicht-geschriebenen Mahlzeiten zählt.
    sync.meals.insertLoggedMeal(entry).then((_) {
      _queueStatsDelta(meals: 1);
    }).catchError((Object e) {
      _reportSyncError('Mahlzeit', e);
      if (mounted) {
        setState(() {
          loggedMeals = prevMeals;
          lifetimeStats = prevStats;
          dailyConsumedKcal = prevKcal;
          macroProgress = prevMacros;
        });
      }
    });
    return entry.id;
  }

  /// Ersetzt das Ergebnis EINER bereits geloggten Mahlzeit (per [id]) durch das
  /// neu skalierte [scaled] und rechnet kcal + ALLE Makros frisch aus der
  /// neu aufgebauten Liste. Das ist der Fix fuer den Makro-Integritaets-Bug:
  /// eine Nach-Portionierung aktualisierte frueher nur die kcal (copyResultWith
  /// Kcal fror Protein/KH/Fett ein) und traf zudem ueber indexWhere die falsche
  /// (erste) Mahlzeit des Tages. [scaled] traegt bereits korrekte P/C/F
  /// (adjustedToGrams/adjustedToItems), daher genuegt ein 1:1-Ersatz.
  void _updateLoggedMealResult(String id, MealAnalysisResult scaled) {
    final index = loggedMeals.indexWhere((m) => m.id == id);
    if (index == -1) return;
    final target = loggedMeals[index];
    final prevMeals = loggedMeals;
    final prevKcal = dailyConsumedKcal;
    final prevMacros = macroProgress;
    final updated = target.copyWith(result: scaled);
    setState(() {
      final nextMeals = [...loggedMeals];
      nextMeals[index] = updated;
      loggedMeals = nextMeals;
      if (_selectedFoodDateIsToday) {
        dailyConsumedKcal = _consumedKcalForFoodDate(DateTime.now());
        macroProgress = _macroProgressForFoodDate(DateTime.now());
      }
    });
    _syncWithRollback(
      'Mahlzeit-Update',
      widget.sync?.meals.updateLoggedMeal(updated),
      () {
        loggedMeals = prevMeals;
        dailyConsumedKcal = prevKcal;
        macroProgress = prevMacros;
      },
    );
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

  /// Wie viele Auto-Recents (nicht angeheftete Eintraege) maximal behalten
  /// werden. Angeheftete Favoriten zaehlen NICHT mit und sind unbegrenzt.
  static const int _maxAutoRecents = 5;

  /// Beim Loggen: merkt sich die Mahlzeit als Auto-Recent. Das Kappen auf
  /// [_maxAutoRecents] betrifft NUR die nicht-angehefteten Eintraege —
  /// angeheftete Favoriten (pinned) bleiben vollstaendig erhalten. Ist die
  /// Mahlzeit bereits angeheftet, bleibt sie pinned (nur addedAt frischt auf).
  void _rememberRecent(MealAnalysisResult result) {
    final id = FavoriteMeal.idFor(result);
    final existing = favorites.where((f) => f.id == id);
    final wasPinned = existing.isNotEmpty && existing.first.pinned;
    final entry = FavoriteMeal(
      id: id,
      result: result,
      addedAt: DateTime.now(),
      pinned: wasPinned,
    );
    favorites = _cappedFavorites([entry, ...favorites.where((f) => f.id != id)]);
    widget.sync?.meals
        .upsertFavorite(entry)
        .catchError((e) => _reportSyncError('Favorit', e));
  }

  /// Behaelt ALLE angehefteten Favoriten und nur die juengsten
  /// [_maxAutoRecents] Auto-Recents — Reihenfolge sonst unveraendert.
  List<FavoriteMeal> _cappedFavorites(List<FavoriteMeal> source) {
    final pinned = source.where((f) => f.pinned).toList(growable: false);
    final recents =
        source.where((f) => !f.pinned).take(_maxAutoRecents).toList();
    return [...pinned, ...recents];
  }

  /// True, wenn die Mahlzeit aktuell als Favorit angeheftet ist (Herz gefuellt).
  bool _isFavorite(MealAnalysisResult result) {
    final id = FavoriteMeal.idFor(result);
    final matches = favorites.where((f) => f.id == id);
    return matches.isNotEmpty && matches.first.pinned;
  }

  /// Heftet eine Mahlzeit als Favorit an bzw. loest die Anheftung wieder.
  /// Angeheftet -> persistiert via upsertFavorite(pinned:true). Loesen ->
  /// die Zeile faellt zurueck auf einen Auto-Recent (pinned:false) und
  /// unterliegt wieder dem Recents-Cap; ist sie dann ueber dem Cap, faellt
  /// sie raus (deleteFavorite). So bleibt „Favoriten" exakt die User-Auswahl.
  void _toggleFavorite(MealAnalysisResult result) {
    HapticFeedback.selectionClick();
    final id = FavoriteMeal.idFor(result);
    final existing = favorites.where((f) => f.id == id);
    final isPinned = existing.isNotEmpty && existing.first.pinned;
    final prev = favorites;

    if (isPinned) {
      // Anheftung loesen -> wieder Auto-Recent. Cap kann ihn verdraengen.
      final downgraded = existing.first.copyWith(pinned: false);
      final next = _cappedFavorites(
        [...favorites.where((f) => f.id != id), downgraded]
          ..sort((a, b) => b.addedAt.compareTo(a.addedAt)),
      );
      final survived = next.any((f) => f.id == id);
      setState(() => favorites = next);
      if (survived) {
        _syncWithRollback(
          'Favorit',
          widget.sync?.meals.upsertFavorite(downgraded),
          () => favorites = prev,
        );
      } else {
        _syncWithRollback(
          'Favorit-Delete',
          widget.sync?.meals.deleteFavorite(id),
          () => favorites = prev,
        );
      }
    } else {
      // Anheften: vorhandene Zeile hochstufen oder eine neue pinned anlegen.
      final entry = existing.isNotEmpty
          ? existing.first.copyWith(pinned: true)
          : FavoriteMeal(
              id: id, result: result, addedAt: DateTime.now(), pinned: true);
      setState(() {
        favorites = [entry, ...favorites.where((f) => f.id != id)];
      });
      _syncWithRollback(
        'Favorit',
        widget.sync?.meals.upsertFavorite(entry),
        () => favorites = prev,
      );
    }
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
      // Angeheftete kommen ungekappt zurueck; Auto-Recents wieder mit Cap.
      favorites = fav.pinned
          ? [fav, ...favorites]
          : _cappedFavorites([fav, ...favorites]);
    });
    _syncWithRollback(
      'Favorit-Restore',
      widget.sync?.meals.upsertFavorite(fav),
      () => favorites = favorites.where((f) => f.id != fav.id).toList(),
    );
  }

  /// Persistiert ein selbst angelegtes Rezept (PROD-2). Optimistisch lokal
  /// vornan, dann user_recipes.upsert. Bei Fehler: lokal zurueckrollen, sonst
  /// loege die „gespeichert"-Bestaetigung (Rezept ueberlebt sonst keinen
  /// Neustart). Der upsert ist auf (user_id, slug) idempotent.
  void _createUserRecipe(FitnessRecipe recipe) {
    final prev = _userRecipes;
    setState(() {
      _userRecipes = [recipe, ..._userRecipes.where((r) => r.slug != recipe.slug)];
    });
    _syncWithRollback(
      'Rezept',
      widget.sync?.userRecipes.upsert(recipe),
      () => _userRecipes = prev,
    );
  }

  /// Loescht ein Eigen-Rezept lokal + via user_recipes.delete(slug).
  void _deleteUserRecipe(String slug) {
    final prev = _userRecipes;
    setState(() {
      _userRecipes = _userRecipes.where((r) => r.slug != slug).toList();
    });
    _syncWithRollback(
      'Rezept-Delete',
      widget.sync?.userRecipes.delete(slug),
      () => _userRecipes = prev,
    );
  }

  Future<void> _openSettings() async {
    final result = await showSettingsSheet(context, profile: profile);
    if (result == null || !mounted) return;
    final wasReset = result.resetDay;
    // Clobber-Guard (DATA-3): den Stand VOR dem Edit festhalten. Stand das
    // angezeigte Profil noch auf den nackten Ctor-Defaults (Offline-Kaltstart,
    // weder Server- noch Cache-Hydration geglueckt), darf ein Save die echte
    // Server-Zeile NICHT mit diesen 78/178-Defaults ueberschreiben — der Edit
    // selbst macht aus geratenen Defaults keine echten Werte.
    final canPersistProfile = _hydratedFromRealSource;
    setState(() {
      profile = result.profile;
      if (wasReset) {
        _clearTodayState();
      }
    });
    final sync = widget.sync;
    if (sync != null) {
      // Editiertes Profil nur dann cachen, wenn es auf echten Daten basiert —
      // sonst zementiert der Cache die Defaults als "letzten bekannten Stand".
      if (canPersistProfile) {
        unawaited(
            _cache?.writeProfile(result.profile) ?? Future<void>.value());
      }
      // Profil-Save AWAIT damit Fehler sichtbar werden (Snackbar). Vorher
      // wurde der Future weggeschluckt -> User dachte das Speichern haette
      // funktioniert obwohl er still gescheitert ist.
      try {
        // Profil-Upsert NUR gegen echte Basis-Daten (Clobber-Guard).
        if (canPersistProfile) {
          await sync.profile.save(result.profile);
        } else {
          dev.log(
              'ProfileSync.save uebersprungen: profile basiert auf Ctor-Defaults '
              '(kein Server-/Cache-Hydrate) — Clobber-Schutz',
              name: 'fitpilot_sync');
        }
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

  /// Setzt alle Tages-Zustände zurück. Gemeinsam genutzt vom Settings-Reset und
  /// vom manuellen Reset. MUSS innerhalb eines setState aufgerufen werden.
  void _clearTodayState() {
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

  void _resetTodayData() {
    setState(_clearTodayState);
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
      // Onboarding-Werte sind frisch vom User eingegeben — echte Quelle.
      _hydratedFromRealSource = true;
    });
    final sync = widget.sync;
    if (sync == null) return;
    // Fertiges Profil durabel cachen (gegen Kaltstart-Defaults absichern).
    unawaited(_cache?.writeProfile(finished) ?? Future<void>.value());
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
        onUpdateMeal: _updateLoggedMealResult,
        isFavorite: _isFavorite,
        onToggleFavorite: _toggleFavorite,
        onRemoveFavorite: _removeFavorite,
        onRemoveMeal: _removeLoggedMeal,
      ),
      4 => RecipesScreen(
        onAddMeal: (result, slot) => _addResultToDailyTotal(
          result,
          slot: slot,
          foodDate: DateTime.now(),
        ),
        initialUserRecipes: _userRecipes,
        // Persistenz nur mit echtem Sync (Test/Preview: nur Session-lokal).
        onCreateRecipe: widget.sync == null ? null : _createUserRecipe,
        onDeleteRecipe: widget.sync == null ? null : _deleteUserRecipe,
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


import 'package:flutter/material.dart';

import '../app/home_store.dart';
import '../theme/app_colors.dart';
import '../widgets/common/basic_widgets.dart';
import '../widgets/common/store_selector.dart';
import '../widgets/shared/shiftfit_top_bar.dart';
import '../widgets/today/caffeine_card.dart';
import '../widgets/today/caffeine_half_life_card.dart';
import '../widgets/today/daily_tracker_card.dart';
import '../widgets/today/day_overview_card.dart';
import '../widgets/today/habits_card.dart';
import '../widgets/today/mood_card.dart';
import '../widgets/today/smart_reminders_card.dart';
import '../widgets/today/tip_of_day_card.dart';
import '../widgets/today/today_log_sheet.dart';
import '../widgets/today/today_widgets.dart';
import '../widgets/today/weight_card.dart';
import '../widgets/today/workout_timer_sheet.dart';
import 'today_dashboard_models.dart';

/// PERF-2: Das Today-Dashboard liest seinen Zustand jetzt direkt aus dem
/// [HomeStore] und teilt sich in Sektionen, von denen jede per [StoreSelector]
/// an genau ihre Slice haengt. Frueher baute jeder Quick-Log (Wasser, Mood, …)
/// als monolithisches `setState` ALLE ~16 Karten neu; jetzt rebuildet z.B. ein
/// Wasser-Tap nur die Tracker- und Reminder-Sektion — Wohlbefinden (Mood/Habits/
/// Koffein-Halbwertszeit/Gewicht) und Session (Plan/Streak/Challenge) bleiben
/// stehen. Karten-Reihenfolge, -Keys und -Conditionals sind unveraendert.
class TodayDashboard extends StatelessWidget {
  const TodayDashboard({
    super.key,
    required this.store,
    required this.actions,
    required this.onSettingsPressed,
    this.onProfilePressed,
    this.profileInitial,
  });

  /// Single source of truth (ARCH-4). Die Sektionen selektieren ihre Slices.
  final HomeStore store;

  /// Callback-Buendel (stabil; treibt keine Rebuilds).
  final TodayActions actions;

  /// App-Chrome (TopBar), nicht Teil des Tages-Zustands.
  final VoidCallback onSettingsPressed;
  final VoidCallback? onProfilePressed;
  final String? profileInitial;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('screen-today'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- A: Chrome + Check-in (rebuildet nur bei Shift/Energy/Stress) ----
        StoreSelector(
          store: store,
          selector: () =>
              (store.selectedShift, store.selectedEnergy, store.selectedStress),
          builder: _buildChrome,
        ),
        const SizedBox(height: 14),
        // --- B: Tracker (rebuildet bei Wasser/Schritten/Schlaf/Kcal/Health) --
        StoreSelector(
          store: store,
          selector: () => (
            store.dailyWaterMl,
            store.profile.dailyWaterGoalMl,
            store.dailySteps,
            store.stepsGoal,
            store.lastSleep,
            store.profile.dailySleepGoalMinutes,
            store.dailyConsumedKcal,
            store.profile.dailyKcalGoal,
            store.completedBlockIds,
            store.plan.blocks.length,
            store.healthAuthState,
            store.healthLastFetch,
          ),
          builder: _buildTracker,
        ),
        const SizedBox(height: 20),
        // --- C: Wohlbefinden (rebuildet bei Mood/Habits/Koffein/Gewicht) -----
        StoreSelector(
          store: store,
          selector: () => (
            store.mood,
            store.habits,
            store.caffeineDay,
            store.weightLog,
            store.selectedShift,
          ),
          builder: _buildWellbeing,
        ),
        const SizedBox(height: 16),
        // --- D: Reminders + Tip (rebuildet bei Wasser/Koffein/Schlaf/Shift) --
        StoreSelector(
          store: store,
          selector: () => (
            store.selectedShift,
            store.dailyWaterMl,
            store.profile.dailyWaterGoalMl,
            store.caffeineDay,
            store.lastSleep,
            store.profile.dailySleepGoalMinutes,
          ),
          builder: _buildReminders,
        ),
        const SizedBox(height: 20),
        // --- E: Session + Motivation (rebuildet bei Plan/Blocks/Streak) ------
        StoreSelector(
          store: store,
          selector: () => (
            store.selectedShift,
            store.selectedEnergy,
            store.selectedStress,
            store.completedBlockIds,
            store.workoutStreak,
          ),
          builder: _buildSession,
        ),
      ],
    );
  }

  Widget _buildChrome(BuildContext context) {
    final plan = store.plan;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShiftFitTopBar(
          plan: plan,
          onSettingsPressed: onSettingsPressed,
          onProfilePressed: onProfilePressed,
          profileInitial: profileInitial,
        ),
        const SizedBox(height: 18),
        ShiftFitHero(plan: plan),
        const SizedBox(height: 14),
        FitPilotHubGrid(
          plan: plan,
          onTapWorkout: actions.onOpenTraining,
          onTapNutrition: actions.onOpenFood,
          onTapGuides: () => showPlanSheet(context, plan),
        ),
        const SizedBox(height: 14),
        QuickCheckInCard(
          selectedShift: store.selectedShift,
          selectedEnergy: store.selectedEnergy,
          selectedStress: store.selectedStress,
          plan: plan,
          onShiftSelected: actions.onShiftSelected,
          onEnergySelected: actions.onEnergySelected,
          onStressSelected: actions.onStressSelected,
        ),
      ],
    );
  }

  Widget _buildTracker(BuildContext context) {
    final dailyConsumedKcal = store.dailyConsumedKcal;
    final kcalGoal = store.profile.dailyKcalGoal;
    final dailyWaterMl = store.dailyWaterMl;
    final waterGoalMl = store.profile.dailyWaterGoalMl;
    final dailySteps = store.dailySteps;
    final stepsGoal = store.stepsGoal;
    final lastSleep = store.lastSleep;
    final sleepGoalMinutes = store.profile.dailySleepGoalMinutes;
    final completedCount = store.completedBlockIds.length;
    final total = store.plan.blocks.length;

    final sleepMinutes = lastSleep?.duration.inMinutes ?? 0;
    final double kcalRatio = kcalGoal <= 0
        ? 0.0
        : (dailyConsumedKcal / kcalGoal).clamp(0.0, 1.0).toDouble();
    final double waterRatio = waterGoalMl <= 0
        ? 0.0
        : (dailyWaterMl / waterGoalMl).clamp(0.0, 1.0).toDouble();
    final double stepsRatio = stepsGoal <= 0
        ? 0.0
        : (dailySteps / stepsGoal).clamp(0.0, 1.0).toDouble();
    final double sleepRatio = sleepGoalMinutes <= 0
        ? 0.0
        : (sleepMinutes / sleepGoalMinutes).clamp(0.0, 1.0).toDouble();
    final double workoutRatio =
        total <= 0 ? 0.0 : (completedCount / total).clamp(0.0, 1.0).toDouble();

    // Tracker stats are tappable quick-log entry points (slot-tap pattern):
    // Wasser/Schritte open a focused sheet, Schlaf opens the sleep log, Kcal
    // jumps to the Food tab where meals are logged.
    final stats = <TrackerStat>[
      TrackerStat(
        icon: Icons.local_fire_department_outlined,
        label: 'Kcal',
        value: '$dailyConsumedKcal',
        color: orange,
        ratio: kcalRatio,
        statKey: const ValueKey('tracker-stat-kcal'),
        onTap: actions.onOpenFood,
      ),
      TrackerStat(
        icon: Icons.water_drop_outlined,
        label: 'Wasser',
        value: '${(dailyWaterMl / 1000).toStringAsFixed(1)}L',
        color: cyan,
        ratio: waterRatio,
        statKey: const ValueKey('tracker-stat-water'),
        onTap: () async {
          final ml = await showWaterQuickAddSheet(
            context,
            intakeMl: dailyWaterMl,
            goalMl: waterGoalMl,
          );
          if (ml != null) actions.onAddWater(ml);
        },
      ),
      TrackerStat(
        icon: Icons.directions_walk_outlined,
        label: 'Schritte',
        value: _formatSteps(dailySteps),
        color: lime,
        ratio: stepsRatio,
        statKey: const ValueKey('tracker-stat-steps'),
        onTap: () async {
          final s = await showStepsQuickSetSheet(context, steps: dailySteps);
          if (s != null) actions.onSetSteps(s);
        },
      ),
      TrackerStat(
        icon: Icons.bedtime_outlined,
        label: 'Schlaf',
        value: lastSleep == null
            ? '–'
            : '${(sleepMinutes / 60).toStringAsFixed(sleepMinutes % 60 == 0 ? 0 : 1)}h',
        color: wellnessTone,
        ratio: sleepRatio,
        statKey: const ValueKey('tracker-stat-sleep'),
        onTap: actions.onLogSleep,
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DayOverviewCard(
          waterRatio: waterRatio,
          sleepRatio: sleepRatio,
          workoutRatio: workoutRatio,
          stepsRatio: stepsRatio,
        ),
        const SizedBox(height: 14),
        DailyTrackerCard(
          stats: stats,
          healthAuthState: store.healthAuthState,
          healthLastFetch: store.healthLastFetch,
          onConnectHealth: actions.onConnectHealth,
          onRefreshHealth: actions.onRefreshHealth,
        ),
      ],
    );
  }

  Widget _buildWellbeing(BuildContext context) {
    final caffeineDay = store.caffeineDay;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Wohlbefinden', action: 'heute'),
        const SizedBox(height: 10),
        MoodCard(
          mood: store.mood,
          onMoodChanged: actions.onMoodScore,
          onEditNote: actions.onEditMoodNote,
        ),
        const SizedBox(height: 10),
        HabitsCard(
          habits: defaultHabits,
          state: store.habits,
          onToggle: actions.onToggleHabit,
        ),
        const SizedBox(height: 10),
        CaffeineCard(
          day: caffeineDay,
          shift: store.selectedShift,
          onAdd: actions.onAddCaffeine,
          onReset: actions.onResetCaffeine,
        ),
        if (caffeineDay.entries.isNotEmpty) ...[
          const SizedBox(height: 10),
          CaffeineHalfLifeCard(day: caffeineDay),
        ],
        const SizedBox(height: 10),
        WeightCard(log: store.weightLog, onLog: actions.onLogWeight),
      ],
    );
  }

  Widget _buildReminders(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SmartRemindersCard(
          shift: store.selectedShift,
          dailyWaterMl: store.dailyWaterMl,
          waterGoalMl: store.profile.dailyWaterGoalMl,
          caffeineDay: store.caffeineDay,
          lastBedtimeMinutes: store.lastSleep?.bedtimeMinutes,
          sleepGoalMinutes: store.profile.dailySleepGoalMinutes,
          onAddWater: actions.onAddWater,
        ),
        const SizedBox(height: 10),
        TipOfDayCard(shift: store.selectedShift),
      ],
    );
  }

  Widget _buildSession(BuildContext context) {
    final plan = store.plan;
    final completedBlockIds = store.completedBlockIds;
    final workoutStreak = store.workoutStreak;
    final completedCount = completedBlockIds.length;
    final total = plan.blocks.length;
    final planAction = total == 0
        ? '${plan.totalMinutes} Min'
        : '$completedCount/$total · ${plan.totalMinutes} Min';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Session', action: planAction),
        const SizedBox(height: 10),
        Builder(
          builder: (innerContext) => DailyPlanCard(
            plan: plan,
            completed: completedBlockIds,
            onToggleBlock: actions.onToggleBlock,
            onStartTimer: (block) async {
              final markDone = await showWorkoutTimerSheet(
                innerContext,
                block: block,
                accent: plan.accent,
              );
              if (markDone == true) {
                final index = plan.blocks.indexOf(block) + 1;
                actions.onToggleBlock('$index:${block.title}');
              }
            },
          ),
        ),
        if (workoutStreak > 0) ...[
          const SizedBox(height: 10),
          _StreakBadge(streak: workoutStreak),
        ],
        const SizedBox(height: 20),
        const SectionHeader(title: 'Motivation', action: 'Challenge'),
        const SizedBox(height: 10),
        WeeklyChallengeCard(
          plan: plan,
          completed: workoutStreak.clamp(0, 7),
          total: 7,
        ),
      ],
    );
  }

  static String _formatSteps(int steps) {
    if (steps >= 1000) {
      final k = steps / 1000;
      return '${k.toStringAsFixed(k >= 10 ? 0 : 1)}k';
    }
    return '$steps';
  }
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('workout-streak-badge'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: surfaceSoft,
        borderRadius: BorderRadius.circular(rControl),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_fire_department_outlined,
            size: 16,
            color: orange,
          ),
          const SizedBox(width: 8),
          Text(
            'Workout-Streak: $streak Tage',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

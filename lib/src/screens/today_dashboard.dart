import 'package:flutter/material.dart';

import '../models/caffeine_entry.dart';
import '../models/daily_mood.dart';
import '../models/habit.dart';
import '../models/shift_fit_plan.dart';
import '../models/sleep_entry.dart';
import '../models/weight_log.dart';
import '../services/health_service.dart';
import '../theme/app_colors.dart';
import '../widgets/common/basic_widgets.dart';
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

class TodayDashboard extends StatelessWidget {
  const TodayDashboard({
    super.key,
    required this.selectedShift,
    required this.selectedEnergy,
    required this.selectedStress,
    required this.plan,
    required this.onShiftSelected,
    required this.onEnergySelected,
    required this.onStressSelected,
    required this.dailyConsumedKcal,
    required this.kcalGoal,
    required this.dailyWaterMl,
    required this.waterGoalMl,
    required this.dailySteps,
    required this.stepsGoal,
    required this.lastSleep,
    required this.sleepGoalMinutes,
    required this.completedBlockIds,
    required this.onToggleBlock,
    required this.workoutStreak,
    required this.healthAuthState,
    required this.healthLastFetch,
    required this.onConnectHealth,
    required this.onRefreshHealth,
    required this.onSettingsPressed,
    // Wellness/logging state + handlers (activate the dormant log cards).
    required this.caffeineDay,
    required this.mood,
    required this.habits,
    required this.weightLog,
    required this.onAddWater,
    required this.onSetSteps,
    required this.onLogSleep,
    required this.onMoodScore,
    required this.onEditMoodNote,
    required this.onToggleHabit,
    required this.onAddCaffeine,
    required this.onResetCaffeine,
    required this.onLogWeight,
    required this.onOpenTraining,
    required this.onOpenFood,
    this.onProfilePressed,
    this.profileInitial,
  });

  final String selectedShift;
  final String selectedEnergy;
  final String selectedStress;
  final ShiftFitPlan plan;
  final ValueChanged<String> onShiftSelected;
  final ValueChanged<String> onEnergySelected;
  final ValueChanged<String> onStressSelected;
  final int dailyConsumedKcal;
  final int kcalGoal;
  final int dailyWaterMl;
  final int waterGoalMl;
  final int dailySteps;
  final int stepsGoal;
  final SleepEntry? lastSleep;
  final int sleepGoalMinutes;
  final Set<String> completedBlockIds;
  final ValueChanged<String> onToggleBlock;
  final int workoutStreak;
  final HealthAuthState healthAuthState;
  final DateTime? healthLastFetch;
  final VoidCallback onConnectHealth;
  final VoidCallback onRefreshHealth;
  final VoidCallback onSettingsPressed;

  final CaffeineDay caffeineDay;
  final DailyMood mood;
  final HabitState habits;
  final WeightLog weightLog;
  final ValueChanged<int> onAddWater;
  final ValueChanged<int> onSetSteps;
  final VoidCallback onLogSleep;
  final ValueChanged<int> onMoodScore;
  final VoidCallback onEditMoodNote;
  final ValueChanged<String> onToggleHabit;
  final ValueChanged<int> onAddCaffeine;
  final VoidCallback onResetCaffeine;
  final ValueChanged<double> onLogWeight;
  final VoidCallback onOpenTraining;
  final VoidCallback onOpenFood;

  final VoidCallback? onProfilePressed;
  final String? profileInitial;

  @override
  Widget build(BuildContext context) {
    final completedCount = completedBlockIds.length;
    final total = plan.blocks.length;
    final planAction = total == 0
        ? '${plan.totalMinutes} Min'
        : '$completedCount/$total · ${plan.totalMinutes} Min';

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

    // Tracker stats are now tappable quick-log entry points (slot-tap pattern):
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
        onTap: onOpenFood,
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
          if (ml != null) onAddWater(ml);
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
          if (s != null) onSetSteps(s);
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
        onTap: onLogSleep,
      ),
    ];

    return Column(
      key: const ValueKey('screen-today'),
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
        const SizedBox(height: 12),
        FitPilotHubGrid(
          plan: plan,
          onTapWorkout: onOpenTraining,
          onTapNutrition: onOpenFood,
          onTapGuides: () => showPlanSheet(context, plan),
        ),
        const SizedBox(height: 12),
        QuickCheckInCard(
          selectedShift: selectedShift,
          selectedEnergy: selectedEnergy,
          selectedStress: selectedStress,
          plan: plan,
          onShiftSelected: onShiftSelected,
          onEnergySelected: onEnergySelected,
          onStressSelected: onStressSelected,
        ),
        const SizedBox(height: 12),
        DayOverviewCard(
          waterRatio: waterRatio,
          sleepRatio: sleepRatio,
          workoutRatio: workoutRatio,
          stepsRatio: stepsRatio,
        ),
        const SizedBox(height: 12),
        DailyTrackerCard(
          stats: stats,
          healthAuthState: healthAuthState,
          healthLastFetch: healthLastFetch,
          onConnectHealth: onConnectHealth,
          onRefreshHealth: onRefreshHealth,
        ),
        const SizedBox(height: 20),
        const SectionHeader(title: 'Wohlbefinden', action: 'heute'),
        const SizedBox(height: 10),
        MoodCard(
          mood: mood,
          onMoodChanged: onMoodScore,
          onEditNote: onEditMoodNote,
        ),
        const SizedBox(height: 10),
        HabitsCard(
          habits: defaultHabits,
          state: habits,
          onToggle: onToggleHabit,
        ),
        const SizedBox(height: 10),
        CaffeineCard(
          day: caffeineDay,
          shift: selectedShift,
          onAdd: onAddCaffeine,
          onReset: onResetCaffeine,
        ),
        if (caffeineDay.entries.isNotEmpty) ...[
          const SizedBox(height: 10),
          CaffeineHalfLifeCard(day: caffeineDay),
        ],
        const SizedBox(height: 10),
        WeightCard(log: weightLog, onLog: onLogWeight),
        const SizedBox(height: 16),
        SmartRemindersCard(
          shift: selectedShift,
          dailyWaterMl: dailyWaterMl,
          waterGoalMl: waterGoalMl,
          caffeineDay: caffeineDay,
          lastBedtimeMinutes: lastSleep?.bedtimeMinutes,
          sleepGoalMinutes: sleepGoalMinutes,
          onAddWater: onAddWater,
        ),
        const SizedBox(height: 10),
        TipOfDayCard(shift: selectedShift),
        const SizedBox(height: 20),
        SectionHeader(title: 'Session', action: planAction),
        const SizedBox(height: 10),
        Builder(
          builder: (innerContext) => DailyPlanCard(
            plan: plan,
            completed: completedBlockIds,
            onToggleBlock: onToggleBlock,
            onStartTimer: (block) async {
              final markDone = await showWorkoutTimerSheet(
                innerContext,
                block: block,
                accent: plan.accent,
              );
              if (markDone == true) {
                final index = plan.blocks.indexOf(block) + 1;
                onToggleBlock('$index:${block.title}');
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

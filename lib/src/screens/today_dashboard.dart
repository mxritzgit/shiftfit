import 'package:flutter/material.dart';

import '../models/caffeine_entry.dart';
import '../models/daily_mood.dart';
import '../models/plan_block.dart';
import '../models/shift_fit_plan.dart';
import '../models/sleep_entry.dart';
import '../theme/app_colors.dart';
import '../widgets/common/basic_widgets.dart';
import '../widgets/shared/shiftfit_top_bar.dart';
import '../widgets/today/caffeine_card.dart';
import '../widgets/today/day_overview_card.dart';
import '../widgets/today/mood_card.dart';
import '../widgets/today/steps_card.dart';
import '../widgets/today/smart_reminders_card.dart';
import '../widgets/today/today_widgets.dart';
import '../widgets/today/wellness_widgets.dart';
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
    required this.dailyWaterMl,
    required this.waterGoalMl,
    required this.onAddWater,
    required this.onResetWater,
    required this.lastSleep,
    required this.sleepGoalMinutes,
    required this.onLogSleep,
    required this.completedBlockIds,
    required this.onToggleBlock,
    required this.workoutStreak,
    required this.caffeineDay,
    required this.onAddCaffeine,
    required this.onResetCaffeine,
    required this.dailySteps,
    required this.stepsGoal,
    required this.onAddSteps,
    required this.onSetSteps,
    required this.mood,
    required this.onMoodChanged,
    required this.onEditMoodNote,
    required this.onSettingsPressed,
  });

  final String selectedShift;
  final String selectedEnergy;
  final String selectedStress;
  final ShiftFitPlan plan;
  final ValueChanged<String> onShiftSelected;
  final ValueChanged<String> onEnergySelected;
  final ValueChanged<String> onStressSelected;
  final int dailyWaterMl;
  final int waterGoalMl;
  final ValueChanged<int> onAddWater;
  final VoidCallback onResetWater;
  final SleepEntry? lastSleep;
  final int sleepGoalMinutes;
  final VoidCallback onLogSleep;
  final Set<String> completedBlockIds;
  final ValueChanged<String> onToggleBlock;
  final int workoutStreak;
  final CaffeineDay caffeineDay;
  final ValueChanged<int> onAddCaffeine;
  final VoidCallback onResetCaffeine;
  final int dailySteps;
  final int stepsGoal;
  final ValueChanged<int> onAddSteps;
  final ValueChanged<int> onSetSteps;
  final DailyMood mood;
  final ValueChanged<int> onMoodChanged;
  final VoidCallback onEditMoodNote;
  final VoidCallback onSettingsPressed;

  @override
  Widget build(BuildContext context) {
    final completedCount = completedBlockIds.length;
    final total = plan.blocks.length;
    final planAction = total == 0
        ? '${plan.totalMinutes} Min'
        : '$completedCount/$total · ${plan.totalMinutes} Min';

    final double waterRatio = waterGoalMl <= 0
        ? 0.0
        : (dailyWaterMl / waterGoalMl).clamp(0.0, 1.0).toDouble();
    final sleepMinutes = lastSleep?.duration.inMinutes ?? 0;
    final double sleepRatio = sleepGoalMinutes <= 0
        ? 0.0
        : (sleepMinutes / sleepGoalMinutes).clamp(0.0, 1.0).toDouble();
    final double workoutRatio = total <= 0
        ? 0.0
        : (completedCount / total).clamp(0.0, 1.0).toDouble();
    final double stepsRatio = stepsGoal <= 0
        ? 0.0
        : (dailySteps / stepsGoal).clamp(0.0, 1.0).toDouble();

    return Column(
      key: const ValueKey('screen-today'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShiftFitTopBar(plan: plan, onSettingsPressed: onSettingsPressed),
        const SizedBox(height: 20),
        ShiftFitHero(plan: plan),
        const SizedBox(height: 14),
        DayOverviewCard(
          waterRatio: waterRatio,
          sleepRatio: sleepRatio,
          workoutRatio: workoutRatio,
          stepsRatio: stepsRatio,
        ),
        const SizedBox(height: 14),
        SmartRemindersCard(
          shift: selectedShift,
          dailyWaterMl: dailyWaterMl,
          waterGoalMl: waterGoalMl,
          caffeineDay: caffeineDay,
          lastBedtimeMinutes: lastSleep?.bedtimeMinutes,
          sleepGoalMinutes: sleepGoalMinutes,
        ),
        const SizedBox(height: 14),
        QuickCheckInCard(
          selectedShift: selectedShift,
          selectedEnergy: selectedEnergy,
          selectedStress: selectedStress,
          plan: plan,
          onShiftSelected: onShiftSelected,
          onEnergySelected: onEnergySelected,
          onStressSelected: onStressSelected,
        ),
        const SizedBox(height: 14),
        RecoveryScoreCard(plan: plan),
        const SizedBox(height: 14),
        WaterTrackerCard(
          intakeMl: dailyWaterMl,
          goalMl: waterGoalMl,
          onAdd: onAddWater,
          onReset: onResetWater,
        ),
        const SizedBox(height: 10),
        StepsCard(
          steps: dailySteps,
          goal: stepsGoal,
          onAdd: onAddSteps,
          onSet: onSetSteps,
        ),
        const SizedBox(height: 10),
        CaffeineCard(
          day: caffeineDay,
          shift: selectedShift,
          onAdd: onAddCaffeine,
          onReset: onResetCaffeine,
        ),
        const SizedBox(height: 10),
        SleepLogCard(
          lastEntry: lastSleep,
          goalMinutes: sleepGoalMinutes,
          onLog: onLogSleep,
        ),
        const SizedBox(height: 10),
        MoodCard(
          mood: mood,
          onMoodChanged: onMoodChanged,
          onEditNote: onEditMoodNote,
        ),
        const SizedBox(height: 22),
        SectionHeader(
          title: 'Dein Plan für heute',
          action: planAction,
        ),
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
        const SizedBox(height: 22),
        SectionHeader(title: 'Schicht-Kompass', action: selectedShift),
        const SizedBox(height: 10),
        ShiftTimeline(shift: selectedShift),
        const SizedBox(height: 22),
        const SectionHeader(title: 'Recovery Tools', action: ''),
        const SizedBox(height: 10),
        RecoveryToolsGrid(plan: plan),
        const SizedBox(height: 22),
        const SectionHeader(title: 'Wochenrhythmus', action: ''),
        const SizedBox(height: 10),
        const RhythmWeekCard(),
      ],
    );
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
        borderRadius: BorderRadius.circular(12),
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

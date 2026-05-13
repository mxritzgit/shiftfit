import 'package:flutter/material.dart';

import '../models/shift_fit_plan.dart';
import '../models/sleep_entry.dart';
import '../theme/app_colors.dart';
import '../widgets/common/basic_widgets.dart';
import '../widgets/shared/shiftfit_top_bar.dart';
import '../widgets/today/today_widgets.dart';
import '../widgets/today/wellness_widgets.dart';

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
  final VoidCallback onSettingsPressed;

  @override
  Widget build(BuildContext context) {
    final completedCount = completedBlockIds.length;
    final total = plan.blocks.length;
    final planAction = total == 0
        ? '${plan.totalMinutes} Min'
        : '$completedCount/$total · ${plan.totalMinutes} Min';

    return Column(
      key: const ValueKey('screen-today'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShiftFitTopBar(plan: plan, onSettingsPressed: onSettingsPressed),
        const SizedBox(height: 20),
        ShiftFitHero(plan: plan),
        const SizedBox(height: 16),
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
        SleepLogCard(
          lastEntry: lastSleep,
          goalMinutes: sleepGoalMinutes,
          onLog: onLogSleep,
        ),
        const SizedBox(height: 22),
        SectionHeader(
          title: 'Dein Plan für heute',
          action: planAction,
        ),
        const SizedBox(height: 10),
        DailyPlanCard(
          plan: plan,
          completed: completedBlockIds,
          onToggleBlock: onToggleBlock,
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

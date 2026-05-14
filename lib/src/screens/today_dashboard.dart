import 'package:flutter/material.dart';

import '../models/plan_block.dart';
import '../models/shift_fit_plan.dart';
import '../models/sleep_entry.dart';
import '../services/health_service.dart';
import '../theme/app_colors.dart';
import '../widgets/common/basic_widgets.dart';
import '../widgets/shared/shiftfit_top_bar.dart';
import '../widgets/today/daily_tracker_card.dart';
import '../widgets/today/today_widgets.dart';
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

    final stats = <TrackerStat>[
      TrackerStat(
        icon: Icons.local_fire_department_outlined,
        label: 'Kcal',
        value: '$dailyConsumedKcal',
        color: orange,
        ratio: kcalRatio,
      ),
      TrackerStat(
        icon: Icons.water_drop_outlined,
        label: 'Wasser',
        value: '${(dailyWaterMl / 1000).toStringAsFixed(1)}L',
        color: cyan,
        ratio: waterRatio,
      ),
      TrackerStat(
        icon: Icons.directions_walk_outlined,
        label: 'Schritte',
        value: _formatSteps(dailySteps),
        color: lime,
        ratio: stepsRatio,
      ),
      TrackerStat(
        icon: Icons.bedtime_outlined,
        label: 'Schlaf',
        value: lastSleep == null
            ? '–'
            : '${(sleepMinutes / 60).toStringAsFixed(sleepMinutes % 60 == 0 ? 0 : 1)}h',
        color: pink,
        ratio: sleepRatio,
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
        const SizedBox(height: 20),
        ShiftFitHero(plan: plan),
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
        DailyTrackerCard(
          stats: stats,
          healthAuthState: healthAuthState,
          healthLastFetch: healthLastFetch,
          onConnectHealth: onConnectHealth,
          onRefreshHealth: onRefreshHealth,
        ),
        const SizedBox(height: 22),
        SectionHeader(title: 'Dein Plan für heute', action: planAction),
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


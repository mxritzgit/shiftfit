import 'package:flutter/material.dart';

import '../models/shift_fit_plan.dart';
import '../models/sleep_entry.dart';
import '../theme/app_colors.dart';
import '../widgets/common/basic_widgets.dart';
import '../widgets/shared/shiftfit_top_bar.dart';
import '../widgets/trends/combined_streak_card.dart';
import '../widgets/trends/today_snapshot_card.dart';
import '../widgets/trends/trends_widgets.dart';

class TrendsScreen extends StatelessWidget {
  const TrendsScreen({
    super.key,
    required this.plan,
    required this.weekPlan,
    required this.dailyWaterMl,
    required this.waterGoalMl,
    required this.lastSleep,
    required this.sleepGoalMinutes,
    required this.workoutStreak,
    required this.completedTodayCount,
    required this.totalBlocksToday,
    required this.dailySteps,
    required this.stepsGoal,
    required this.dailyConsumedKcal,
    required this.kcalGoal,
    this.onSettingsPressed,
    this.onProfilePressed,
    this.profileInitial,
  });

  final ShiftFitPlan plan;
  final List<String> weekPlan;
  final int dailyWaterMl;
  final int waterGoalMl;
  final SleepEntry? lastSleep;
  final int sleepGoalMinutes;
  final int workoutStreak;
  final int completedTodayCount;
  final int totalBlocksToday;
  final int dailySteps;
  final int stepsGoal;
  final int dailyConsumedKcal;
  final int kcalGoal;
  final VoidCallback? onSettingsPressed;
  final VoidCallback? onProfilePressed;
  final String? profileInitial;

  int get loadBalance {
    final hardSessions = weekPlan.where((shift) => shift == 'Kraft' || shift == 'Muskelaufbau').length;
    final recoverySlots = weekPlan.where((shift) => shift == 'Mobility' || shift == 'Recovery' || shift == 'Frei').length;
    return (76 + recoverySlots * 4 - hardSessions * 2).clamp(48, 94).toInt();
  }

  @override
  Widget build(BuildContext context) {
    final bars = [
      ('Mo', 0.72, lime),
      ('Di', 0.78, lime),
      ('Mi', 0.64, lime),
      ('Do', 0.69, lime),
      ('Fr', 0.54, lime),
      ('Sa', 0.58, lime),
      ('So', 0.86, lime),
    ];

    final double waterRatio = waterGoalMl <= 0
        ? 0.0
        : (dailyWaterMl / waterGoalMl).clamp(0.0, 1.0).toDouble();
    final sleepMinutes = lastSleep?.duration.inMinutes ?? 0;
    final double sleepRatio = sleepGoalMinutes <= 0
        ? 0.0
        : (sleepMinutes / sleepGoalMinutes).clamp(0.0, 1.0).toDouble();
    final double stepsRatio = stepsGoal <= 0
        ? 0.0
        : (dailySteps / stepsGoal).clamp(0.0, 1.0).toDouble();
    final double readinessRatio = (plan.recoveryScore / 100).clamp(0.0, 1.0);

    final sleepLabel = lastSleep == null
        ? '–'
        : '${(sleepMinutes / 60).toStringAsFixed(sleepMinutes % 60 == 0 ? 0 : 1)}h';

    final stats = <SnapshotStat>[
      SnapshotStat(
        label: 'Readiness',
        value: '${plan.recoveryScore}%',
        color: plan.accent,
        ratio: readinessRatio,
      ),
      SnapshotStat(
        label: 'Schlaf',
        value: sleepLabel,
        color: wellnessTone,
        ratio: sleepRatio,
      ),
      SnapshotStat(
        label: 'Wasser',
        value: '${(dailyWaterMl / 1000).toStringAsFixed(1)}L',
        color: cyan,
        ratio: waterRatio,
      ),
      SnapshotStat(
        label: 'Schritte',
        value: _formatSteps(dailySteps),
        color: lime,
        ratio: stepsRatio,
      ),
    ];

    return Column(
      key: const ValueKey('screen-trends'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShiftFitTopBar(
          plan: plan,
          onSettingsPressed: onSettingsPressed,
          onProfilePressed: onProfilePressed,
          profileInitial: profileInitial,
        ),
        const SizedBox(height: 20),
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Fortschritt bleibt\nsichtbar.',
                style: TextStyle(
                  fontSize: 30,
                  height: 1.08,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Training, Recovery und Routinen auf einen Blick.',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        TodaySnapshotCard(stats: stats),
        const SizedBox(height: 14),
        CombinedStreakCard(
          workoutStreak: workoutStreak,
          completedToday: totalBlocksToday > 0 &&
              completedTodayCount >= totalBlocksToday,
        ),
        const SizedBox(height: 22),
        const SectionHeader(title: 'Progress Verlauf', action: '7 Tage'),
        const SizedBox(height: 10),
        TrendBarsCard(bars: bars),
        const SizedBox(height: 22),
        const SectionHeader(title: 'Insights', action: ''),
        const SizedBox(height: 10),
        InsightsCard(plan: plan, loadBalance: loadBalance),
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

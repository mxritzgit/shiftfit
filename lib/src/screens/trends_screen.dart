import 'package:flutter/material.dart';

import '../models/achievement.dart';
import '../models/shift_fit_plan.dart';
import '../models/sleep_entry.dart';
import '../theme/app_colors.dart';
import '../widgets/common/basic_widgets.dart';
import '../widgets/shared/shiftfit_top_bar.dart';
import '../widgets/trends/achievements_strip.dart';
import '../widgets/trends/streak_calendar.dart';
import '../widgets/trends/trends_widgets.dart';
import '../widgets/trends/wellness_trend_widgets.dart';
import '../widgets/week/week_widgets.dart';

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

  int get streak => 5 + weekPlan.where((shift) => shift == 'Frei').length;

  int get loadBalance {
    final nights = weekPlan.where((shift) => shift == 'Nacht').length;
    final free = weekPlan.where((shift) => shift == 'Frei').length;
    return (74 + free * 4 - nights * 6).clamp(48, 94).toInt();
  }

  @override
  Widget build(BuildContext context) {
    final bars = [
      ('Mo', 0.72, lime),
      ('Di', 0.78, lime),
      ('Mi', 0.64, orange),
      ('Do', 0.69, orange),
      ('Fr', 0.54, pink),
      ('Sa', 0.58, pink),
      ('So', 0.86, cyan),
    ];

    final double waterRatio = waterGoalMl <= 0
        ? 0.0
        : (dailyWaterMl / waterGoalMl).clamp(0.0, 1.0).toDouble();
    final waterPercent = (waterRatio * 100).round();

    final sleepMinutes = lastSleep?.duration.inMinutes ?? 0;
    final double sleepRatio = sleepGoalMinutes <= 0
        ? 0.0
        : (sleepMinutes / sleepGoalMinutes).clamp(0.0, 1.5).toDouble();
    final sleepHours = (sleepMinutes / 60).toStringAsFixed(
      sleepMinutes % 60 == 0 ? 0 : 1,
    );

    final double workoutRatio = totalBlocksToday <= 0
        ? 0.0
        : (completedTodayCount / totalBlocksToday).clamp(0.0, 1.0).toDouble();

    final double stepsRatio = stepsGoal <= 0
        ? 0.0
        : (dailySteps / stepsGoal).clamp(0.0, 1.0).toDouble();

    final waterBars = _syntheticBars(
      todayRatio: waterRatio,
      color: cyan,
      seed: 5,
    );
    final sleepBars = _syntheticBars(
      todayRatio: sleepRatio.clamp(0.0, 1.0).toDouble(),
      color: pink,
      seed: 7,
    );

    final achievements = const AchievementCatalog().evaluate(
      workoutStreak: workoutStreak,
      dailyWaterMl: dailyWaterMl,
      waterGoalMl: waterGoalMl,
      sleepMinutes: sleepMinutes,
      sleepGoalMinutes: sleepGoalMinutes,
      dailyKcal: dailyConsumedKcal,
      kcalGoal: kcalGoal,
      stepsToday: dailySteps,
      stepsGoal: stepsGoal,
      limeColor: lime,
      cyanColor: cyan,
      orangeColor: orange,
      pinkColor: pink,
    );

    return Column(
      key: const ValueKey('screen-trends'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShiftFitTopBar(plan: plan, onSettingsPressed: onSettingsPressed),
        const SizedBox(height: 20),
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StatusPill(label: 'Trends', color: lime),
              const SizedBox(height: 16),
              const Text(
                'Readiness bleibt\nsteuerbar.',
                style: TextStyle(
                  fontSize: 28,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sieh, wann Training zieht und Recovery mehr bringt.',
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
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                icon: Icons.favorite_outline,
                title: 'Readiness',
                value: '${plan.recoveryScore}%',
                color: plan.accent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SummaryCard(
                icon: Icons.local_fire_department_outlined,
                title: 'Streak',
                value: '$streak Tage',
                color: orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SummaryCard(
          icon: Icons.balance,
          title: 'Belastungsbalance',
          value: '$loadBalance%',
          color: cyan,
        ),
        const SizedBox(height: 22),
        const SectionHeader(title: 'Wellness heute', action: ''),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TrendStatCard(
                icon: Icons.water_drop_outlined,
                label: 'Wasser',
                value: '$dailyWaterMl ml',
                color: cyan,
                subtitle: '$waterPercent% vom Ziel',
                ratio: waterRatio,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TrendStatCard(
                icon: Icons.bedtime_outlined,
                label: 'Schlaf',
                value: lastSleep == null ? '–' : '${sleepHours}h',
                color: pink,
                subtitle: lastSleep == null
                    ? 'Noch nichts geloggt'
                    : 'Ziel ${(sleepGoalMinutes / 60).toStringAsFixed(1)}h',
                ratio: sleepRatio.clamp(0.0, 1.0).toDouble(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TrendStatCard(
                icon: Icons.directions_walk_outlined,
                label: 'Schritte',
                value: '$dailySteps',
                color: lime,
                subtitle: 'Ziel $stepsGoal',
                ratio: stepsRatio,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TrendStatCard(
                icon: Icons.local_fire_department_rounded,
                label: 'Workout-Streak',
                value: '$workoutStreak Tage',
                color: orange,
                subtitle: workoutStreak > 0 ? 'Weiter so' : 'Heute starten',
                ratio: (workoutStreak / 14).clamp(0.0, 1.0).toDouble(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TrendStatCard(
          icon: Icons.checklist_rounded,
          label: 'Plan heute',
          value: '$completedTodayCount/$totalBlocksToday',
          color: lime,
          subtitle: 'Workout-Blöcke fertig',
          ratio: workoutRatio,
        ),
        const SizedBox(height: 22),
        const SectionHeader(title: '4-Wochen-Streak', action: ''),
        const SizedBox(height: 10),
        StreakCalendar(
          workoutStreak: workoutStreak,
          completedToday: totalBlocksToday > 0 &&
              completedTodayCount >= totalBlocksToday,
        ),
        const SizedBox(height: 22),
        const SectionHeader(title: 'Achievements', action: ''),
        const SizedBox(height: 10),
        AchievementsStrip(achievements: achievements),
        const SizedBox(height: 22),
        const SectionHeader(title: 'Readiness Verlauf', action: '7 Tage'),
        const SizedBox(height: 10),
        TrendBarsCard(bars: bars),
        const SizedBox(height: 14),
        WeeklyBarsCard(
          title: 'Wasser',
          subtitle: '7 Tage · Ziel $waterGoalMl ml',
          bars: waterBars,
        ),
        const SizedBox(height: 10),
        WeeklyBarsCard(
          title: 'Schlaf',
          subtitle: 'letzte Nächte',
          bars: sleepBars,
        ),
        const SizedBox(height: 22),
        const SectionHeader(title: 'Insights', action: ''),
        const SizedBox(height: 10),
        InsightsCard(plan: plan, loadBalance: loadBalance),
      ],
    );
  }

  static List<(String, double, Color)> _syntheticBars({
    required double todayRatio,
    required Color color,
    required int seed,
  }) {
    const labels = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    return [
      for (var i = 0; i < labels.length; i++)
        (
          labels[i],
          i == labels.length - 1
              ? todayRatio.clamp(0.05, 1.0).toDouble()
              : (0.45 + (((i + seed) * 13) % 50) / 100)
                  .clamp(0.05, 1.0)
                  .toDouble(),
          color,
        ),
    ];
  }
}

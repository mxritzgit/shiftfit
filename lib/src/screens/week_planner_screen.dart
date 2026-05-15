import 'package:flutter/material.dart';

import '../models/shift_fit_plan.dart';
import '../theme/app_colors.dart';
import '../widgets/common/basic_widgets.dart';
import '../widgets/shared/shiftfit_top_bar.dart';
import '../widgets/week/week_widgets.dart';

class WeekPlannerScreen extends StatelessWidget {
  const WeekPlannerScreen({
    super.key,
    required this.plan,
    required this.weekPlan,
    required this.onShiftChanged,
    this.onSettingsPressed,
    this.onProfilePressed,
    this.profileInitial,
  });

  static const days = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
  static const shifts = ['Kraft', 'Muskelaufbau', 'Ausdauer', 'Mobility', 'Recovery', 'Frei'];

  final ShiftFitPlan plan;
  final List<String> weekPlan;
  final void Function(int dayIndex, String shift) onShiftChanged;
  final VoidCallback? onSettingsPressed;
  final VoidCallback? onProfilePressed;
  final String? profileInitial;

  int get strengthDays =>
      weekPlan.where((shift) => shift == 'Kraft' || shift == 'Muskelaufbau').length;

  int get recoveryDays =>
      weekPlan.where((shift) => shift == 'Mobility' || shift == 'Recovery' || shift == 'Frei').length;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('screen-week'),
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
              const StatusPill(label: 'FitnessPlan', color: cyan),
              const SizedBox(height: 16),
              const Text(
                'Trainingswoche,\nsmart geplant.',
                style: TextStyle(
                  fontSize: 28,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Kraft, Ausdauer und Recovery so verteilen, dass Fortschritt planbar bleibt.',
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
                icon: Icons.fitness_center,
                title: 'Kraft & Aufbau',
                value: '$strengthDays Krafttage',
                color: lime,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SummaryCard(
                icon: Icons.spa_rounded,
                title: 'Regeneration',
                value: '$recoveryDays Recovery',
                color: pink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        const SectionHeader(title: 'Trainingssplit', action: 'Antippen'),
        const SizedBox(height: 10),
        for (var dayIndex = 0; dayIndex < days.length; dayIndex++) ...[
          WeekDayPlannerRow(
            day: days[dayIndex],
            selectedShift: weekPlan[dayIndex],
            shifts: shifts,
            onShiftChanged: (shift) => onShiftChanged(dayIndex, shift),
          ),
          if (dayIndex != days.length - 1) const SizedBox(height: 8),
        ],
        const SizedBox(height: 22),
        const SectionHeader(title: 'Planungstipps', action: ''),
        const SizedBox(height: 10),
        PlanningTipsCard(weekPlan: weekPlan),
      ],
    );
  }
}

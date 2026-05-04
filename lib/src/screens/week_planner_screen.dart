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
  });

  static const days = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
  static const shifts = ['Früh', 'Spät', 'Nacht', 'Frei'];

  final ShiftFitPlan plan;
  final List<String> weekPlan;
  final void Function(int dayIndex, String shift) onShiftChanged;

  int get trainingDays =>
      weekPlan.where((shift) => shift == 'Frei' || shift == 'Früh').length;

  int get nightBlocks => weekPlan.where((shift) => shift == 'Nacht').length;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('screen-week'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShiftFitTopBar(plan: plan),
        const SizedBox(height: 24),
        AppCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StatusPill(label: 'Woche planen', color: cyan),
              const SizedBox(height: 18),
              const Text(
                '7 Tage,\nsauber getaktet.',
                style: TextStyle(
                  fontSize: 40,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Wähle deine Schichten und halte Training, Licht und Schlaf realistisch.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.64),
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                icon: Icons.fitness_center,
                title: 'Training',
                value: '$trainingDays Tage',
                color: lime,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SummaryCard(
                icon: Icons.nightlight_round,
                title: 'Nächte',
                value: '$nightBlocks geplant',
                color: pink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const SectionHeader(title: 'Schichtplan', action: 'Antippen'),
        const SizedBox(height: 12),
        for (var dayIndex = 0; dayIndex < days.length; dayIndex++) ...[
          WeekDayPlannerRow(
            day: days[dayIndex],
            selectedShift: weekPlan[dayIndex],
            shifts: shifts,
            onShiftChanged: (shift) => onShiftChanged(dayIndex, shift),
          ),
          if (dayIndex != days.length - 1) const SizedBox(height: 10),
        ],
        const SizedBox(height: 18),
        const SectionHeader(title: 'Planungstipps', action: '3 Hinweise'),
        const SizedBox(height: 12),
        PlanningTipsCard(weekPlan: weekPlan),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../common/basic_widgets.dart';
import '../common/selection_widgets.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: Colors.white.withValues(alpha: 0.58))),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class WeekDayPlannerRow extends StatelessWidget {
  const WeekDayPlannerRow({
    super.key,
    required this.day,
    required this.selectedShift,
    required this.shifts,
    required this.onShiftChanged,
  });

  final String day;
  final String selectedShift;
  final List<String> shifts;
  final ValueChanged<String> onShiftChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(day, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final shift in shifts)
                  ShiftChoiceChip(
                    key: ValueKey('week-$day-$shift'),
                    label: shift,
                    selected: shift == selectedShift,
                    color: shiftColor(shift),
                    onTap: () => onShiftChanged(shift),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PlanningTipsCard extends StatelessWidget {
  const PlanningTipsCard({super.key, required this.weekPlan});

  final List<String> weekPlan;

  @override
  Widget build(BuildContext context) {
    final nights = weekPlan.where((shift) => shift == 'Nacht').length;
    final freeDays = weekPlan.where((shift) => shift == 'Frei').length;
    final tips = [
      nights > 0
          ? 'Nach Nachtschichten: Sonnenbrille heimwärts, Schlafraum kühl und dunkel.'
          : 'Ohne Nachtschicht: Schlafanker möglichst konstant halten.',
      freeDays > 1
          ? 'Freie Tage eignen sich für Krafttraining und Meal Prep.'
          : 'Bei wenig frei: kurze Recovery-Sessions höher priorisieren.',
      'Härtere Einheiten auf Früh- oder freie Tage legen, Spätdienste eher mobilisieren.',
    ];

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          for (var i = 0; i < tips.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: cyan.withValues(alpha: 0.16),
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(color: cyan, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tips[i],
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.68),
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (i != tips.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

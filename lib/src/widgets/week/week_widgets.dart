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
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(rChip),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
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
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              day,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textMuted,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
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
    final strengthDays = weekPlan.where((shift) => shift == 'Kraft' || shift == 'Muskelaufbau').length;
    final recoveryDays = weekPlan.where((shift) => shift == 'Mobility' || shift == 'Recovery' || shift == 'Frei').length;
    final tips = [
      strengthDays >= 3
          ? 'Drei Kraftreize reichen: Gewichte sauber steigern, nicht jeden Satz ausmaxen.'
          : 'Zu wenig Kraftreiz: eine kurze Ganzkörper-Session ergänzen.',
      recoveryDays >= 2
          ? 'Recovery ist eingeplant: Mobility und Schlaf schützen die Progression.'
          : 'Mindestens zwei leichte Tage halten Gelenke und Nervensystem frisch.',
      'Wger-Prinzip: große Bewegungsmuster zuerst, Accessory danach, Core zum Abschluss.',
    ];

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          for (var i = 0; i < tips.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: cyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(rChip),
                  ),
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      color: cyan,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tips[i],
                    style: const TextStyle(
                      color: textPrimary,
                      fontSize: 13,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
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

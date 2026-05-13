import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../common/basic_widgets.dart';

class StreakCalendar extends StatelessWidget {
  const StreakCalendar({
    super.key,
    required this.workoutStreak,
    required this.completedToday,
  });

  /// Length of current streak ending today.
  final int workoutStreak;

  /// Whether today's plan has been fully completed.
  final bool completedToday;

  static const int _weeks = 4;
  static const int _daysPerWeek = 7;
  static const int _totalDays = _weeks * _daysPerWeek;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(const Duration(days: _totalDays - 1));

    // Streak fills the most-recent `workoutStreak` days, plus today only if
    // explicitly marked completedToday.
    final activeDays = <int>{};
    final streakEnd = completedToday ? _totalDays - 1 : _totalDays - 2;
    for (var i = 0; i < workoutStreak; i++) {
      final idx = streakEnd - i;
      if (idx >= 0 && idx < _totalDays) {
        activeDays.add(idx);
      }
    }

    return AppCard(
      key: const ValueKey('streak-calendar'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Aktivität',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '${activeDays.length} / $_totalDays Tage',
                style: const TextStyle(
                  color: textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 6.0;
              final cellSize = (constraints.maxWidth -
                      spacing * (_daysPerWeek - 1)) /
                  _daysPerWeek;
              return Column(
                children: [
                  for (var w = 0; w < _weeks; w++) ...[
                    Row(
                      children: [
                        for (var d = 0; d < _daysPerWeek; d++) ...[
                          _DayCell(
                            size: cellSize,
                            isToday: w * _daysPerWeek + d == _totalDays - 1,
                            isActive: activeDays.contains(w * _daysPerWeek + d),
                            date: start.add(Duration(days: w * _daysPerWeek + d)),
                          ),
                          if (d != _daysPerWeek - 1)
                            const SizedBox(width: spacing),
                        ],
                      ],
                    ),
                    if (w != _weeks - 1) const SizedBox(height: spacing),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _LegendDot(color: lime, label: 'Plan fertig'),
              const SizedBox(width: 12),
              _LegendDot(color: hairline, label: 'offen'),
              const Spacer(),
              Text(
                'Streak $workoutStreak',
                style: const TextStyle(
                  color: orange,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.size,
    required this.isToday,
    required this.isActive,
    required this.date,
  });

  final double size;
  final bool isToday;
  final bool isActive;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '${date.day}.${date.month}.',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isActive ? lime.withValues(alpha: 0.78) : surfaceSoft,
          borderRadius: BorderRadius.circular(7),
          border: isToday
              ? Border.all(color: lime, width: 1.5)
              : Border.all(color: hairline),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

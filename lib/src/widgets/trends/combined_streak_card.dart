import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../common/basic_widgets.dart';

class CombinedStreakCard extends StatelessWidget {
  const CombinedStreakCard({
    super.key,
    required this.workoutStreak,
    required this.completedToday,
  });

  final int workoutStreak;
  final bool completedToday;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      key: const ValueKey('combined-streak-card'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: orange.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: orange,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$workoutStreak Tage Streak',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      workoutStreak == 0
                          ? 'Heute starten'
                          : 'Letzte 4 Wochen',
                      style: const TextStyle(
                        color: textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Calendar(
            workoutStreak: workoutStreak,
            completedToday: completedToday,
          ),
        ],
      ),
    );
  }
}

/// Thin wrapper that reuses StreakCalendar but strips its own card chrome so
/// we don't get a card-in-card look.
class _Calendar extends StatelessWidget {
  const _Calendar({
    required this.workoutStreak,
    required this.completedToday,
  });

  final int workoutStreak;
  final bool completedToday;

  static const int _weeks = 4;
  static const int _daysPerWeek = 7;
  static const int _totalDays = _weeks * _daysPerWeek;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(const Duration(days: _totalDays - 1));

    final activeDays = <int>{};
    final streakEnd = completedToday ? _totalDays - 1 : _totalDays - 2;
    for (var i = 0; i < workoutStreak; i++) {
      final idx = streakEnd - i;
      if (idx >= 0 && idx < _totalDays) {
        activeDays.add(idx);
      }
    }

    return LayoutBuilder(
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
                    _Cell(
                      size: cellSize,
                      isToday: w * _daysPerWeek + d == _totalDays - 1,
                      isActive: activeDays.contains(w * _daysPerWeek + d),
                      date: start.add(Duration(days: w * _daysPerWeek + d)),
                    ),
                    if (d != _daysPerWeek - 1) const SizedBox(width: spacing),
                  ],
                ],
              ),
              if (w != _weeks - 1) const SizedBox(height: spacing),
            ],
          ],
        );
      },
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
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
          borderRadius: BorderRadius.circular(6),
          border: isToday
              ? Border.all(color: lime, width: 1.5)
              : Border.all(color: hairline),
        ),
      ),
    );
  }
}

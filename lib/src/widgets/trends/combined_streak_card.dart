import 'package:flutter/material.dart';

import '../../services/daily_log_sync.dart';
import '../../theme/app_colors.dart';
import '../common/basic_widgets.dart';

/// 28-Tage Workout-Kalender. Eine Zelle = ein Kalendertag der letzten 4 Wochen.
/// Aktiv (lime) wenn an dem Tag `workoutCompleted == true` in der History steht.
/// KEIN Rueckwaerts-Fuellen mehr aus einem Counter — jede Zelle ist echte Historie.
class CombinedStreakCard extends StatelessWidget {
  const CombinedStreakCard({
    super.key,
    required this.workoutStreak,
    required this.completedToday,
    this.history = const <DailyLog>[],
  });

  /// Echte Streak-Zahl (vom Parent-Widget geliefert, aus lifetime_stats/History).
  final int workoutStreak;

  /// Ob heute alle Bloecke abgeschlossen sind (Today-Signal, ergaenzt History
  /// fuer den aktuellen Tag falls noch kein workout_completed-Flush erfolgte).
  final bool completedToday;

  /// Letzte ~28-30 Tage, aufsteigend sortiert. Defensiv: darf leer sein.
  final List<DailyLog> history;

  @override
  Widget build(BuildContext context) {
    // Wie viele der letzten 28 Tage hatten ein Workout — fuer das Sublabel.
    final activeCount = _activeDayCount(history, completedToday);

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
                  borderRadius: BorderRadius.circular(rChip),
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
                        fontFeatures: [FontFeature.tabularFigures()],
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
              // Trainingstage im 28-Tage-Fenster — kompakte Dichte ohne Deko.
              Text(
                '$activeCount/28',
                style: const TextStyle(
                  color: textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // A11y: 28-Tage-Raster ansagen statt 28 einzelne Tooltip-Knoten.
          Semantics(
            label: 'Workout-Kalender, letzte 4 Wochen',
            value: '$activeCount von 28 Tagen trainiert, '
                'aktuelle Streak $workoutStreak Tage',
            child: ExcludeSemantics(
              child: _Calendar(
                history: history,
                completedToday: completedToday,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static int _activeDayCount(List<DailyLog> history, bool completedToday) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final byDay = _historyByDay(history);
    var count = 0;
    for (var i = 0; i < _Calendar._totalDays; i++) {
      final day = today.subtract(Duration(days: _Calendar._totalDays - 1 - i));
      final key = _dayKey(day);
      final isToday = day == today;
      final active = (byDay[key]?.workoutCompleted ?? false) ||
          (isToday && completedToday);
      if (active) count++;
    }
    return count;
  }
}

/// `Map<dayKey, DailyLog>` fuer O(1)-Lookup je Kalenderzelle.
Map<int, DailyLog> _historyByDay(List<DailyLog> history) {
  final map = <int, DailyLog>{};
  for (final log in history) {
    final d = log.date;
    map[_dayKey(DateTime(d.year, d.month, d.day))] = log;
  }
  return map;
}

/// Stabiler, vergleichbarer Tages-Schluessel (kein Zeitanteil).
int _dayKey(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

/// 4x7-Raster echter Kalendertage. Letzte Zelle = heute.
class _Calendar extends StatelessWidget {
  const _Calendar({
    required this.history,
    required this.completedToday,
  });

  final List<DailyLog> history;
  final bool completedToday;

  static const int _weeks = 4;
  static const int _daysPerWeek = 7;
  static const int _totalDays = _weeks * _daysPerWeek;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(const Duration(days: _totalDays - 1));
    final byDay = _historyByDay(history);

    bool activeFor(DateTime day) {
      final isToday = day == today;
      final logged = byDay[_dayKey(day)]?.workoutCompleted ?? false;
      // Heute zusaetzlich aus dem Live-Today-Signal speisen, falls der
      // workout_completed-Flush fuer heute noch nicht in der History ist.
      return logged || (isToday && completedToday);
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
                    Builder(builder: (context) {
                      final dayIndex = w * _daysPerWeek + d;
                      final date = start.add(Duration(days: dayIndex));
                      return _Cell(
                        size: cellSize,
                        isToday: dayIndex == _totalDays - 1,
                        isActive: activeFor(date),
                        date: date,
                      );
                    }),
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
          borderRadius: BorderRadius.circular(rChip),
          border: isToday
              ? Border.all(color: lime, width: 1.5)
              : Border.all(color: hairline),
        ),
      ),
    );
  }
}

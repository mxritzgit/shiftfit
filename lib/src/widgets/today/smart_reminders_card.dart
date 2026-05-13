import 'package:flutter/material.dart';

import '../../models/caffeine_entry.dart';
import '../../theme/app_colors.dart';
import '../common/basic_widgets.dart';

class SmartReminder {
  const SmartReminder({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;
}

class SmartRemindersCard extends StatelessWidget {
  const SmartRemindersCard({
    super.key,
    required this.shift,
    required this.dailyWaterMl,
    required this.waterGoalMl,
    required this.caffeineDay,
    required this.lastBedtimeMinutes,
    required this.sleepGoalMinutes,
  });

  final String shift;
  final int dailyWaterMl;
  final int waterGoalMl;
  final CaffeineDay caffeineDay;

  /// Bedtime minutes-of-day from the last sleep log, or null.
  final int? lastBedtimeMinutes;
  final int sleepGoalMinutes;

  List<SmartReminder> _build() {
    final now = DateTime.now();
    final reminders = <SmartReminder>[];

    // Hydration nudge: if it's after 11 and water is < 40% of goal.
    if (now.hour >= 11 &&
        waterGoalMl > 0 &&
        dailyWaterMl < (waterGoalMl * 0.4).round()) {
      final missing = waterGoalMl - dailyWaterMl;
      reminders.add(SmartReminder(
        icon: Icons.water_drop_outlined,
        title: 'Wasser nachlegen',
        body: 'Noch $missing ml bis zum Tagesziel.',
        color: cyan,
      ));
    }

    // Caffeine cutoff: within 60 min of cutoff.
    final cutoff = _cutoffMinutes(shift);
    final mins = now.hour * 60 + now.minute;
    if (mins >= cutoff - 60 && mins < cutoff && caffeineDay.entries.isNotEmpty) {
      reminders.add(SmartReminder(
        icon: Icons.coffee_outlined,
        title: 'Koffein-Stopp bald',
        body: 'Letzte Tasse vor ${_label(cutoff)} hilft dem Schlaf.',
        color: orange,
      ));
    }

    // Sleep prep window: 90 min before bedtime.
    if (lastBedtimeMinutes != null) {
      var bedtime = lastBedtimeMinutes!;
      if (bedtime < mins) {
        bedtime += 24 * 60;
      }
      final delta = bedtime - mins;
      if (delta > 0 && delta <= 90) {
        reminders.add(SmartReminder(
          icon: Icons.bedtime_outlined,
          title: 'Schlaf-Runway',
          body: 'In ${delta} Min ins Bett — Licht dimmen, Screens weg.',
          color: pink,
        ));
      }
    }

    // Shift-specific morning anchor.
    if (now.hour < 9 && shift == 'Früh') {
      reminders.add(const SmartReminder(
        icon: Icons.wb_sunny_outlined,
        title: 'Tageslicht',
        body: '10 Min Sonne vor der Schicht stabilisiert den Rhythmus.',
        color: lime,
      ));
    }

    return reminders;
  }

  int _cutoffMinutes(String shift) {
    switch (shift) {
      case 'Nacht':
        return 26 * 60;
      case 'Spät':
        return 18 * 60;
      case 'Frei':
        return 14 * 60;
      default:
        return 13 * 60;
    }
  }

  String _label(int minutes) {
    final h = (minutes ~/ 60) % 24;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final reminders = _build();
    if (reminders.isEmpty) {
      return const SizedBox.shrink();
    }

    return AppCard(
      key: const ValueKey('smart-reminders-card'),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.tips_and_updates_outlined,
                color: orange,
                size: 16,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Tipps für jetzt',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${reminders.length} Hinweis${reminders.length == 1 ? '' : 'e'}',
                style: const TextStyle(
                  color: textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < reminders.length; i++) ...[
            _ReminderRow(reminder: reminders[i]),
            if (i != reminders.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({required this.reminder});

  final SmartReminder reminder;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: reminder.color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(reminder.icon, color: reminder.color, size: 14),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reminder.title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                reminder.body,
                style: const TextStyle(
                  color: textMuted,
                  fontSize: 11,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

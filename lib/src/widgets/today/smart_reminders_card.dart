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
    this.onTap,
    this.actionLabel,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;

  /// Optional one-tap action that resolves the nudge (e.g. log 250 ml water).
  final VoidCallback? onTap;

  /// Short label for the action chip shown when [onTap] is set.
  final String? actionLabel;
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
    this.onAddWater,
  });

  final String shift;
  final int dailyWaterMl;
  final int waterGoalMl;
  final CaffeineDay caffeineDay;

  /// Bedtime minutes-of-day from the last sleep log, or null.
  final int? lastBedtimeMinutes;
  final int sleepGoalMinutes;

  /// When set, the hydration nudge becomes actionable: tapping logs the given
  /// amount of water (ml) immediately, no sheet needed.
  final ValueChanged<int>? onAddWater;

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
        actionLabel: onAddWater == null ? null : '+250 ml',
        onTap: onAddWater == null ? null : () => onAddWater!(250),
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
          color: wellnessTone,
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.tips_and_updates_outlined,
                color: orange,
                size: 17,
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'Tipps für jetzt',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
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
          const SizedBox(height: 12),
          for (var i = 0; i < reminders.length; i++) ...[
            _ReminderRow(reminder: reminders[i]),
            if (i != reminders.length - 1) const SizedBox(height: 10),
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
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: reminder.color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(rControl),
          ),
          child: Icon(reminder.icon, color: reminder.color, size: 15),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reminder.title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                reminder.body,
                style: const TextStyle(
                  color: textMuted,
                  fontSize: 12,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (reminder.onTap != null && reminder.actionLabel != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: reminder.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(rChip),
              border: Border.all(color: reminder.color.withValues(alpha: 0.30)),
            ),
            child: Text(
              reminder.actionLabel!,
              style: TextStyle(
                color: reminder.color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );

    if (reminder.onTap == null) return row;

    return InkWell(
      onTap: reminder.onTap,
      borderRadius: BorderRadius.circular(rControl),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: row,
      ),
    );
  }
}

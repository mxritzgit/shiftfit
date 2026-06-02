import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/caffeine_entry.dart';
import '../../models/daily_mood.dart';
import '../../models/habit.dart';
import '../../models/sleep_entry.dart';
import '../../models/weight_log.dart';
import '../../theme/app_colors.dart';
import '../common/app_snack.dart';

class DaySummary {
  const DaySummary({
    required this.dailyConsumedKcal,
    required this.kcalGoal,
    required this.dailyWaterMl,
    required this.waterGoalMl,
    required this.dailySteps,
    required this.stepsGoal,
    required this.caffeineDay,
    required this.lastSleep,
    required this.mood,
    required this.shift,
    required this.habits,
    required this.habitDefinitions,
    required this.completedBlocks,
    required this.totalBlocks,
    required this.workoutStreak,
    required this.weightLog,
  });

  final int dailyConsumedKcal;
  final int kcalGoal;
  final int dailyWaterMl;
  final int waterGoalMl;
  final int dailySteps;
  final int stepsGoal;
  final CaffeineDay caffeineDay;
  final SleepEntry? lastSleep;
  final DailyMood mood;
  final String shift;
  final HabitState habits;
  final List<Habit> habitDefinitions;
  final int completedBlocks;
  final int totalBlocks;
  final int workoutStreak;
  final WeightLog weightLog;

  String toShareableText() {
    final now = DateTime.now();
    final date =
        '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';
    final lines = <String>[
      'FitPilot · $date',
      'Fokus: $shift',
      '',
      'Kcal:    $dailyConsumedKcal / $kcalGoal',
      'Wasser:  $dailyWaterMl / $waterGoalMl ml',
      'Schritte: $dailySteps / $stepsGoal',
      if (caffeineDay.entries.isNotEmpty)
        'Koffein: ${caffeineDay.totalMg} mg in ${caffeineDay.cups} Tasse${caffeineDay.cups == 1 ? '' : 'n'}',
      if (lastSleep != null)
        'Schlaf:  ${lastSleep!.durationLabel} (${lastSleep!.bedtimeLabel} → ${lastSleep!.wakeLabel}), Q ${lastSleep!.quality}/5',
      'Plan:    $completedBlocks / $totalBlocks Blöcke',
      'Streak:  $workoutStreak Tage',
      if (weightLog.latest != null)
        'Gewicht: ${weightLog.latest!.weightKg.toStringAsFixed(1)} kg',
      if (mood.isSet) 'Stimmung: ${mood.emoji} ${mood.label}',
      if (mood.note.isNotEmpty) 'Notiz: ${mood.note}',
    ];

    final habitLines = <String>[];
    for (final h in habitDefinitions) {
      final mark = habits.isDone(h.id) ? '✓' : '·';
      habitLines.add('  $mark ${h.title}');
    }
    if (habitLines.isNotEmpty) {
      lines.add('');
      lines.add('Routinen:');
      lines.addAll(habitLines);
    }

    return lines.join('\n');
  }
}

Future<void> showDaySummarySheet(
  BuildContext context, {
  required DaySummary summary,
}) {
  final text = summary.toShareableText();
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: surface,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tageszusammenfassung',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Dein Tag auf einen Blick — kopier ihn dir raus.',
              style: TextStyle(
                color: textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceSoft,
                borderRadius: BorderRadius.circular(rControl),
                border: Border.all(color: hairline),
              ),
              child: SelectableText(
                text,
                key: const ValueKey('day-summary-text'),
                style: const TextStyle(
                  color: textPrimary,
                  fontSize: 12,
                  fontFamily: 'monospace',
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const ValueKey('day-summary-copy'),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: text));
                  if (sheetContext.mounted) {
                    Navigator.pop(sheetContext);
                    showAppSnack(context, 'Zusammenfassung kopiert.',
                        icon: Icons.content_copy_rounded, accent: cyan);
                  }
                },
                icon: const Icon(Icons.copy_rounded, size: 17),
                label: const Text(
                  'In Zwischenablage kopieren',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: lime,
                  foregroundColor: bg,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(rControl),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

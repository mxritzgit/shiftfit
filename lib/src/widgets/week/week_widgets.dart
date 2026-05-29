import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../common/basic_widgets.dart';
import '../common/selection_widgets.dart';

/// Static training-type knowledge that gives each weekday real depth without
/// touching the live `ShiftFitPlan` generator (which is energy/stress driven).
/// Focus + volume + exercise hints per shift type for the per-day detail sheet.
class ShiftMeta {
  const ShiftMeta({
    required this.shift,
    required this.icon,
    required this.focus,
    required this.volume,
    required this.exercises,
  });

  final String shift;
  final IconData icon;

  /// Short one-line focus hint shown on the day row and in the sheet header.
  final String focus;

  /// Compact volume guideline (sets x reps / minutes) for the sheet.
  final String volume;

  /// 2-3 concrete movement cues for the sheet.
  final List<String> exercises;

  Color get color => shiftColor(shift);

  static const Map<String, ShiftMeta> _byShift = {
    'Kraft': ShiftMeta(
      shift: 'Kraft',
      icon: Icons.fitness_center_rounded,
      focus: 'Schwere Grundübungen, lange Pausen',
      volume: '3-5 Arbeitssätze · 3-5 Wdh · 3 Min Pause',
      exercises: [
        'Kniebeuge oder Hinge zuerst, technisch sauber',
        'Eine horizontale + eine vertikale Druck/Zug-Übung',
        'Core-Bracing zum Abschluss, kein Ausmaxen',
      ],
    ),
    'Muskelaufbau': ShiftMeta(
      shift: 'Muskelaufbau',
      icon: Icons.repeat_rounded,
      focus: 'Hypertrophie-Volumen, kontrolliertes Tempo',
      volume: '3-4 Sätze · 8-12 Wdh · 60-90 Sek Pause',
      exercises: [
        'Compound zuerst, dann gezielte Accessory-Supersets',
        '1-2 Wdh Reserve pro Satz, sauberes Tempo',
        'Schultern, Rücken und Glutes mit Fokus pumpen',
      ],
    ),
    'Ausdauer': ShiftMeta(
      shift: 'Ausdauer',
      icon: Icons.favorite_border_rounded,
      focus: 'Zone 2 Basis plus kurze Technik-Spitzen',
      volume: '20-40 Min · Sprechtempo · Puls gleichmäßig',
      exercises: [
        'Locker einlaufen, Nasenatmung als Tempo-Limiter',
        'Gleichmäßige Zone-2-Phase, kein Pulsdruck',
        '4 kurze Steigerungen, nicht sprinten',
      ],
    ),
    'Mobility': ShiftMeta(
      shift: 'Mobility',
      icon: Icons.self_improvement_rounded,
      focus: 'Beweglichkeit öffnen, Gelenke pflegen',
      volume: '15-25 Min · 2-3 Runden · ruhig atmen',
      exercises: [
        'Hüfte, T-Spine und Sprunggelenke mobilisieren',
        'Aktive Dehnungen statt langem Halten',
        'Lange Ausatmung, Schultern sinken lassen',
      ],
    ),
    'Recovery': ShiftMeta(
      shift: 'Recovery',
      icon: Icons.spa_rounded,
      focus: 'Bewusster Deload, Puls niedrig halten',
      volume: '10-20 Min · sehr leicht · Erholung im Fokus',
      exercises: [
        'Lockerer Zone-1-Walk oder leichtes Radeln',
        'Mobility-Reset für die müdesten Bereiche',
        'Atemroutine: 4-7-8, Nervensystem runterfahren',
      ],
    ),
    'Frei': ShiftMeta(
      shift: 'Frei',
      icon: Icons.bedtime_rounded,
      focus: 'Kompletter Ruhetag, Regeneration zulassen',
      volume: 'Kein Training · Schlaf & Ernährung priorisieren',
      exercises: [
        'Schlaf auf 7-9 Stunden bringen',
        'Protein halten, ausreichend trinken',
        'Spaziergang an der frischen Luft ist genug',
      ],
    ),
  };

  static ShiftMeta of(String shift) {
    return _byShift[shift] ??
        const ShiftMeta(
          shift: 'Frei',
          icon: Icons.bedtime_rounded,
          focus: 'Ruhetag',
          volume: 'Kein Training',
          exercises: ['Erholung priorisieren'],
        );
  }
}

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
              fontFeatures: [FontFeature.tabularFigures()],
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
    this.onOpenDetail,
  });

  final String day;
  final String selectedShift;
  final List<String> shifts;
  final ValueChanged<String> onShiftChanged;

  /// Tapping the day label / focus zone opens the per-day detail sheet.
  /// Inline chips stay the fast path for changing the type.
  final VoidCallback? onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final meta = ShiftMeta.of(selectedShift);
    final header = Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(
            day,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Icon(meta.icon, size: 14, color: meta.color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            meta.focus,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: textMuted,
            ),
          ),
        ),
        if (onOpenDetail != null)
          const Icon(Icons.chevron_right_rounded, size: 18, color: textMuted),
      ],
    );

    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (onOpenDetail != null)
            GestureDetector(
              key: ValueKey('week-$day-detail'),
              behavior: HitTestBehavior.opaque,
              onTap: onOpenDetail,
              child: header,
            )
          else
            header,
          const SizedBox(height: 10),
          Wrap(
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
        ],
      ),
    );
  }
}

/// Week-volume snapshot: training vs recovery vs rest day balance.
/// Uses distinct labels so it never collides with the SummaryCard counters
/// ("X Krafttage" / "X Recovery") that the tests pin byte-exactly.
class WeekVolumeCard extends StatelessWidget {
  const WeekVolumeCard({super.key, required this.weekPlan});

  final List<String> weekPlan;

  int _count(bool Function(String) test) => weekPlan.where(test).length;

  @override
  Widget build(BuildContext context) {
    final training = _count(
      (s) => s == 'Kraft' || s == 'Muskelaufbau' || s == 'Ausdauer',
    );
    final mobility = _count((s) => s == 'Mobility' || s == 'Recovery');
    final rest = _count((s) => s == 'Frei');

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _VolumeBar(
            label: 'Training',
            count: training,
            total: 7,
            color: lime,
          ),
          const SizedBox(height: 10),
          _VolumeBar(
            label: 'Mobility & Recovery',
            count: mobility,
            total: 7,
            color: wellnessTone,
          ),
          const SizedBox(height: 10),
          _VolumeBar(
            label: 'Ruhetage',
            count: rest,
            total: 7,
            color: macroCarbs,
          ),
        ],
      ),
    );
  }
}

class _VolumeBar extends StatelessWidget {
  const _VolumeBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  final String label;
  final int count;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final double ratio = total == 0 ? 0.0 : (count / total).clamp(0.0, 1.0).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '$count/$total',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(rPill),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: surfaceSoft,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

/// Lime-pill save ritual. Shows transient "Plan gespeichert ✓" feedback so the
/// user can SEE the plan persists. Feedback state is owned by the parent.
class SavePlanBar extends StatelessWidget {
  const SavePlanBar({
    super.key,
    required this.onSave,
    required this.showSaved,
  });

  final VoidCallback onSave;
  final bool showSaved;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: showSaved
                ? Row(
                    key: const ValueKey('week-save-confirm'),
                    children: const [
                      Icon(Icons.check_circle_rounded, color: lime, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Plan gespeichert ✓',
                        style: TextStyle(
                          color: lime,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : const Text(
                    'Änderungen am Split sichern',
                    key: ValueKey('week-save-hint'),
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        FilledButton(
          key: const ValueKey('week-save-plan'),
          onPressed: onSave,
          style: FilledButton.styleFrom(
            backgroundColor: lime,
            foregroundColor: bg,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: const StadiumBorder(),
          ),
          child: const Text(
            'Plan speichern',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

/// Per-day detail sheet (entity-tap → modal sheet). Lets the user pick the
/// training type AND read focus / volume / exercise cues for the day.
Future<void> showWeekDaySheet(
  BuildContext context, {
  required String day,
  required String selectedShift,
  required List<String> shifts,
  required ValueChanged<String> onShiftChanged,
}) {
  var current = selectedShift;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: surface,
    showDragHandle: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(rSheet)),
    ),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          // Keep latest pick inside the sheet for live preview.
          final meta = ShiftMeta.of(current);
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              4,
              20,
              20 + MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: meta.color.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(rControl),
                        ),
                        child: Icon(meta.icon, color: meta.color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$day · ${meta.shift}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              meta.focus,
                              style: const TextStyle(
                                color: textMuted,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const FieldLabel('TRAININGSTYP'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final shift in shifts)
                        ShiftChoiceChip(
                          key: ValueKey('week-sheet-$day-$shift'),
                          label: shift,
                          selected: shift == current,
                          color: shiftColor(shift),
                          onTap: () {
                            onShiftChanged(shift);
                            setSheetState(() => current = shift);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: surfaceSoft,
                      borderRadius: BorderRadius.circular(rControl),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.bar_chart_rounded,
                          size: 16,
                          color: textMuted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            meta.volume,
                            style: const TextStyle(
                              color: textPrimary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const FieldLabel('FOKUS HEUTE'),
                  const SizedBox(height: 10),
                  for (var i = 0; i < meta.exercises.length; i++) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 5),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: meta.color,
                            borderRadius: BorderRadius.circular(rPill),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            meta.exercises[i],
                            style: const TextStyle(
                              color: textPrimary,
                              fontSize: 13,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (i != meta.exercises.length - 1)
                      const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const ValueKey('week-sheet-done'),
                      onPressed: () => Navigator.pop(sheetContext),
                      style: FilledButton.styleFrom(
                        backgroundColor: lime,
                        foregroundColor: bg,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(rControl),
                        ),
                      ),
                      child: const Text(
                        'Fertig',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
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

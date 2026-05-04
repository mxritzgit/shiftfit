import 'package:flutter/material.dart';

import '../../models/plan_block.dart';
import '../../models/shift_fit_plan.dart';
import '../../theme/app_colors.dart';
import '../common/basic_widgets.dart';
import '../common/selection_widgets.dart';

class ShiftFitHero extends StatelessWidget {
  const ShiftFitHero({super.key, required this.plan});

  final ShiftFitPlan plan;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusPill(label: 'Für deinen Rhythmus', color: plan.accent),
          const SizedBox(height: 18),
          const Text(
            'Train smart.\nRecover better.',
            style: TextStyle(
              fontSize: 46,
              height: 0.98,
              fontWeight: FontWeight.w900,
              letterSpacing: -2.2,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Kurze Empfehlungen passend zu deiner Schicht.',
            style: TextStyle(
              fontSize: 17,
              height: 1.35,
              color: Colors.white.withValues(alpha: 0.64),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              MetricChip(icon: Icons.timer, label: '${plan.totalMinutes} Min'),
              MetricChip(icon: Icons.speed, label: plan.intensity),
              MetricChip(icon: Icons.favorite, label: '${plan.recoveryScore}% Readiness'),
            ],
          ),
        ],
      ),
    );
  }
}

class QuickCheckInCard extends StatelessWidget {
  const QuickCheckInCard({
    super.key,
    required this.selectedShift,
    required this.selectedEnergy,
    required this.selectedStress,
    required this.plan,
    required this.onShiftSelected,
    required this.onEnergySelected,
    required this.onStressSelected,
  });

  final String selectedShift;
  final String selectedEnergy;
  final String selectedStress;
  final ShiftFitPlan plan;
  final ValueChanged<String> onShiftSelected;
  final ValueChanged<String> onEnergySelected;
  final ValueChanged<String> onStressSelected;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Heute',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                ),
              ),
              StatusPill(label: 'Check-in', color: plan.accent),
            ],
          ),
          const SizedBox(height: 16),
          const FieldLabel('Schicht'),
          const SizedBox(height: 8),
          SegmentedOptions(
            options: const ['Früh', 'Spät', 'Nacht', 'Frei'],
            selectedValue: selectedShift,
            onSelected: onShiftSelected,
          ),
          const SizedBox(height: 14),
          const FieldLabel('Energie'),
          const SizedBox(height: 8),
          SegmentedOptions(
            options: const ['Müde', 'Normal', 'Stark'],
            selectedValue: selectedEnergy,
            onSelected: onEnergySelected,
          ),
          const SizedBox(height: 14),
          const FieldLabel('Stress'),
          const SizedBox(height: 8),
          SegmentedOptions(
            options: const ['Niedrig', 'Mittel', 'Hoch'],
            selectedValue: selectedStress,
            onSelected: onStressSelected,
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: plan.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: plan.accent.withValues(alpha: 0.22)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.recommendation,
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  plan.focus,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const ValueKey('today-open-plan'),
                    style: FilledButton.styleFrom(
                      backgroundColor: plan.accent,
                      foregroundColor: bg,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: () => showPlanSheet(context, plan),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text(
                      'Plan öffnen',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RecoveryScoreCard extends StatelessWidget {
  const RecoveryScoreCard({super.key, required this.plan});

  final ShiftFitPlan plan;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          SizedBox(
            width: 86,
            height: 86,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: plan.recoveryScore / 100,
                  strokeWidth: 9,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  color: plan.accent,
                  strokeCap: StrokeCap.round,
                ),
                Text(
                  '${plan.recoveryScore}',
                  style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recovery Score',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  plan.tagline,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.64),
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DailyPlanCard extends StatelessWidget {
  const DailyPlanCard({super.key, required this.plan});

  final ShiftFitPlan plan;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          for (var i = 0; i < plan.blocks.length; i++) ...[
            PlanBlockTile(block: plan.blocks[i], accent: plan.accent, index: i + 1),
            if (i != plan.blocks.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class PlanBlockTile extends StatelessWidget {
  const PlanBlockTile({
    super.key,
    required this.block,
    required this.accent,
    required this.index,
  });

  final PlanBlock block;
  final Color accent;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: accent.withValues(alpha: 0.16),
            child: Icon(block.icon, color: accent, size: 22),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$index. ${block.title}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 3),
                Text(
                  block.description,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.58)),
                ),
              ],
            ),
          ),
          Text(
            block.duration,
            style: TextStyle(color: accent, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class ShiftTimeline extends StatelessWidget {
  const ShiftTimeline({super.key, required this.shift});

  final String shift;

  List<String> get _events {
    switch (shift) {
      case 'Spät':
        return ['Licht', 'Training', 'Meal Prep', 'Schicht', 'Runterfahren'];
      case 'Nacht':
        return ['Nap', 'Aktivieren', 'Schicht', 'Sonnenbrille', 'Schlaf'];
      case 'Frei':
        return ['Schlafanker', 'Training', 'Einkauf', 'Recovery', 'Planung'];
      default:
        return ['Wach', 'Licht', 'Schicht', 'Training', 'Schlafanker'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = _events;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              for (var i = 0; i < events.length; i++) ...[
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: i == 2 ? lime : Colors.white.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        events[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: i == 2 ? 0.95 : 0.58),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                if (i != events.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 27),
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Der Kompass zeigt dir, wann Training, Licht und Schlaf am wenigsten mit deiner Schicht kollidieren.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.58), height: 1.35),
          ),
        ],
      ),
    );
  }
}

class RecoveryToolsGrid extends StatelessWidget {
  const RecoveryToolsGrid({super.key, required this.plan});

  final ShiftFitPlan plan;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RecoveryToolCard(
          icon: Icons.bedtime,
          title: 'Sleep Anchor',
          body: plan.sleepHint,
          color: pink,
        ),
        const SizedBox(height: 12),
        RecoveryToolCard(
          icon: Icons.restaurant,
          title: 'Fuel Reminder',
          body: plan.fuelHint,
          color: orange,
        ),
        const SizedBox(height: 12),
        RecoveryToolCard(
          icon: Icons.air,
          title: 'Breath Reset',
          body: plan.breathHint,
          color: cyan,
        ),
      ],
    );
  }
}

class RecoveryToolCard extends StatelessWidget {
  const RecoveryToolCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withValues(alpha: 0.14),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.62), height: 1.32),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RhythmWeekCard extends StatelessWidget {
  const RhythmWeekCard({super.key});

  @override
  Widget build(BuildContext context) {
    const days = [
      ('Mo', 'Früh', lime),
      ('Di', 'Früh', lime),
      ('Mi', 'Spät', orange),
      ('Do', 'Spät', orange),
      ('Fr', 'Nacht', pink),
      ('Sa', 'Nacht', pink),
      ('So', 'Frei', cyan),
    ];

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (final day in days)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: day.$3.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: day.$3.withValues(alpha: 0.18)),
                    ),
                    child: Column(
                      children: [
                        Text(day.$1, style: const TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        RotatedBox(
                          quarterTurns: 3,
                          child: Text(
                            day.$2,
                            style: TextStyle(
                              color: day.$3,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Als nächstes: echte Wochenplanung, gespeicherte Check-ins und adaptive Empfehlungen.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.58), height: 1.35),
          ),
        ],
      ),
    );
  }
}

void showPlanSheet(BuildContext context, ShiftFitPlan plan) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: surface,
    showDragHandle: true,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(22, 6, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              plan.recommendation,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              plan.tagline,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.65), height: 1.35),
            ),
            const SizedBox(height: 16),
            for (final block in plan.blocks) ...[
              Row(
                children: [
                  Icon(block.icon, color: plan.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${block.title} · ${block.duration}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${plan.recommendation} ist vorgemerkt.')),
                  );
                },
                child: const Text('Für heute vormerken'),
              ),
            ),
          ],
        ),
      );
    },
  );
}

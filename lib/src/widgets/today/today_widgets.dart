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
    return Container(
      key: const ValueKey('today-ios-hero'),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF12180E), bg, Colors.black],
        ),
        borderRadius: BorderRadius.circular(rSheet),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: cardShadow,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -26,
            top: -22,
            child: Container(
              width: 142,
              height: 142,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: lime.withValues(alpha: 0.13),
              ),
            ),
          ),
          Positioned(
            right: 10,
            bottom: 70,
            child: Transform.rotate(
              angle: -0.18,
              child: Container(
                width: 76,
                height: 104,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(rCard),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      lime.withValues(alpha: 0.70),
                      plan.accent.withValues(alpha: 0.42),
                    ],
                  ),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: Icon(
                  Icons.fitness_center_rounded,
                  color: Colors.white.withValues(alpha: 0.72),
                  size: 34,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: _TodayEyebrow(label: 'FITPILOT COACH'),
                  ),
                  _HeroMetric(value: '${plan.totalMinutes} Min', label: 'Dauer'),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 250,
                child: Text(
                  plan.recommendation,
                  style: const TextStyle(
                    fontSize: 29,
                    height: 1.08,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1.0,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                plan.focus,
                style: TextStyle(
                  color: plan.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 280,
                child: Text(
                  plan.tagline,
                  style: const TextStyle(
                    color: Color(0xB3FFFFFF),
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _HeroMetric(value: plan.intensity, label: 'Intensität')),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HeroMetric(
                      value: '${plan.recoveryScore}',
                      label: 'Readiness',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const ValueKey('today-open-plan'),
                  style: FilledButton.styleFrom(
                    backgroundColor: lime,
                    foregroundColor: bg,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () => showPlanSheet(context, plan),
                  icon: const Icon(Icons.play_arrow_rounded, size: 19),
                  label: const Text(
                    'Plan starten',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TodayEyebrow extends StatelessWidget {
  const _TodayEyebrow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: lime,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 9),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xA6FFFFFF),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(rCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0x8CFFFFFF),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class FitPilotHubGrid extends StatelessWidget {
  const FitPilotHubGrid({
    super.key,
    required this.plan,
    this.onTapWorkout,
    this.onTapNutrition,
    this.onTapChallenge,
    this.onTapGuides,
  });

  final ShiftFitPlan plan;

  /// Optional navigation callbacks. When non-null the matching tile becomes
  /// tappable and routes to the relevant tab/sheet; when null it stays inert.
  final VoidCallback? onTapWorkout;
  final VoidCallback? onTapNutrition;
  final VoidCallback? onTapChallenge;
  final VoidCallback? onTapGuides;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      key: const ValueKey('fitpilot-hub-grid'),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 6, 8, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Dein Fitness-Hub',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                Text(
                  'heute',
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _HubTile(
                  keyValue: const ValueKey('hub-tile-workout'),
                  icon: Icons.fitness_center_rounded,
                  title: 'Workout',
                  subtitle: '${plan.totalMinutes} Min',
                  color: lime,
                  onTap: onTapWorkout,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HubTile(
                  keyValue: const ValueKey('hub-tile-nutrition'),
                  icon: Icons.restaurant_rounded,
                  title: 'Nutrition',
                  subtitle: 'Protein zuerst',
                  color: lime,
                  onTap: onTapNutrition,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _HubTile(
                  keyValue: const ValueKey('hub-tile-challenge'),
                  icon: Icons.emoji_events_rounded,
                  title: 'Challenge',
                  subtitle: '7 Tage Reset',
                  color: lime,
                  onTap: onTapChallenge,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HubTile(
                  keyValue: const ValueKey('hub-tile-guides'),
                  icon: Icons.play_circle_rounded,
                  title: 'Guides',
                  subtitle: 'Form & Tipps',
                  color: lime,
                  onTap: onTapGuides,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HubTile extends StatelessWidget {
  const _HubTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
    this.keyValue,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  final Key? keyValue;

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceSoft,
        borderRadius: BorderRadius.circular(rCard),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(rControl),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return tile;

    return InkWell(
      key: keyValue,
      onTap: onTap,
      borderRadius: BorderRadius.circular(rCard),
      child: tile,
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
    final recoveryCopy = selectedStress == 'Hoch'
        ? 'Heute sauber trainieren, nicht erzwingen.'
        : 'Weniger Regler, klarere Entscheidung.';

    return AppCard(
      key: const ValueKey('today-micro-checkin'),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Körpergefühl',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              StatusPill(label: selectedShift, color: plan.accent),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            recoveryCopy,
            style: const TextStyle(
              color: textMuted,
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          const FieldLabel('FOKUS'),
          const SizedBox(height: 8),
          SegmentedOptions(
            options: const ['Kraft', 'Muskelaufbau', 'Ausdauer', 'Recovery'],
            selectedValue: selectedShift,
            onSelected: onShiftSelected,
          ),
          const SizedBox(height: 14),
          const FieldLabel('ENERGIE'),
          const SizedBox(height: 8),
          SegmentedOptions(
            options: const ['Müde', 'Normal', 'Stark'],
            selectedValue: selectedEnergy,
            onSelected: onEnergySelected,
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
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: plan.recoveryScore / 100,
                  strokeWidth: 5,
                  backgroundColor: hairline,
                  color: plan.accent,
                  strokeCap: StrokeCap.round,
                ),
                Text(
                  '${plan.recoveryScore}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Readiness Score',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  plan.tagline,
                  style: const TextStyle(
                    color: textMuted,
                    fontSize: 13,
                    height: 1.4,
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
  const DailyPlanCard({
    super.key,
    required this.plan,
    this.completed = const <String>{},
    this.onToggleBlock,
    this.onStartTimer,
  });

  final ShiftFitPlan plan;
  final Set<String> completed;
  final ValueChanged<String>? onToggleBlock;
  final ValueChanged<PlanBlock>? onStartTimer;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      key: const ValueKey('today-session-card'),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          for (var i = 0; i < plan.blocks.length; i++)
            PlanBlockTile(
              block: plan.blocks[i],
              accent: plan.accent,
              index: i + 1,
              done: completed.contains(_idFor(plan.blocks[i], i)),
              onToggle: onToggleBlock == null
                  ? null
                  : () => onToggleBlock!(_idFor(plan.blocks[i], i)),
              onStartTimer: onStartTimer == null
                  ? null
                  : () => onStartTimer!(plan.blocks[i]),
            ),
        ],
      ),
    );
  }

  static String _idFor(PlanBlock block, int index) => '$index:${block.title}';
}

class PlanBlockTile extends StatelessWidget {
  const PlanBlockTile({
    super.key,
    required this.block,
    required this.accent,
    required this.index,
    this.done = false,
    this.onToggle,
    this.onStartTimer,
  });

  final PlanBlock block;
  final Color accent;
  final int index;
  final bool done;
  final VoidCallback? onToggle;
  final VoidCallback? onStartTimer;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onStartTimer ?? onToggle,
      borderRadius: BorderRadius.circular(rControl),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: done ? 0.22 : 0.12),
                borderRadius: BorderRadius.circular(rControl),
              ),
              child: Icon(block.icon, color: accent, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$index. ${block.title}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      decoration: done ? TextDecoration.lineThrough : null,
                      color: done ? textMuted : textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    block.description,
                    style: const TextStyle(color: textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              block.duration,
              style: TextStyle(
                color: done ? textMuted : textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (onToggle != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onToggle,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  key: ValueKey('plan-block-toggle-$index'),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: done ? accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(rChip),
                    border: Border.all(
                      color: done ? accent : textMuted.withValues(alpha: 0.45),
                    ),
                  ),
                  child: done
                      ? Icon(Icons.check_rounded, color: bg, size: 16)
                      : null,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ShiftTimeline extends StatelessWidget {
  const ShiftTimeline({super.key, required this.shift});

  final String shift;

  List<String> get _events {
    switch (shift) {
      case 'Kraft':
        return ['Warm-up', 'Heavy Lift', 'Push/Pull', 'Core', 'Cooldown'];
      case 'Ausdauer':
        return ['Warm-up', 'Zone 2', 'Strides', 'Cooldown', 'Fuel'];
      case 'Recovery':
        return ['Mobility', 'Walk', 'Breath', 'Protein', 'Sleep'];
      default:
        return ['Warm-up', 'Compound', 'Accessory', 'Core', 'Recovery'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = _events;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          for (var i = 0; i < events.length; i++) ...[
            Expanded(
              child: Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: i == 2 ? lime : hairline,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    events[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: i == 2 ? textPrimary : textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (i != events.length - 1)
              Container(
                width: 16,
                height: 1,
                margin: const EdgeInsets.only(bottom: 20),
                color: hairline,
              ),
          ],
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
          icon: Icons.bedtime_outlined,
          title: 'Sleep Coach',
          body: plan.sleepHint,
          color: wellnessTone,
        ),
        const SizedBox(height: 10),
        RecoveryToolCard(
          icon: Icons.restaurant_outlined,
          title: 'Fuel Strategy',
          body: plan.fuelHint,
          color: lime,
        ),
        const SizedBox(height: 10),
        RecoveryToolCard(
          icon: Icons.air,
          title: 'Breath Reset',
          body: plan.breathHint,
          color: lime,
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
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(rControl),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: const TextStyle(
                    color: textMuted,
                    fontSize: 12,
                    height: 1.4,
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

class WeeklyChallengeCard extends StatelessWidget {
  const WeeklyChallengeCard({
    super.key,
    required this.plan,
    this.completed = 3,
    this.total = 7,
    this.onTap,
  });

  final ShiftFitPlan plan;

  /// Real challenge progress. [completed] active days out of [total]. Defaults
  /// keep the previous static "3/7" reading until the orchestrator wires real
  /// data (e.g. workoutStreak clamped to 7, or active days from history).
  final int completed;
  final int total;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final int safeTotal = total <= 0 ? 7 : total;
    final int safeDone = completed.clamp(0, safeTotal);
    final double ratio = safeDone / safeTotal;

    final card = Container(
      key: const ValueKey('weekly-challenge-card'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(rSheet),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF18230E), bg],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusPill(label: 'WEEKLY CHALLENGE', color: lime),
                const SizedBox(height: 12),
                const Text(
                  'Strong Start Week',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '3 Workouts, 2 Protein-Ziele und ein Mobility-Finish. Kurz genug für volle Wochen, stark genug für Fortschritt.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(rPill),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.10),
                    color: lime,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _ChallengeMetric(value: '$safeDone/$safeTotal', label: 'Tage'),
                    const SizedBox(width: 8),
                    _ChallengeMetric(value: plan.intensity, label: 'Level'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 74,
            height: 116,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(rSheet),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: lime,
              size: 38,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return card;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(rSheet),
      child: card,
    );
  }
}

class _ChallengeMetric extends StatelessWidget {
  const _ChallengeMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(rControl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: -0.2,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
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
      ('Mo', 'K', lime),
      ('Di', 'H', lime),
      ('Mi', 'A', orange),
      ('Do', 'M', cyan),
      ('Fr', 'K', lime),
      ('Sa', 'R', wellnessTone),
      ('So', '·', cyan),
    ];

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          for (final day in days)
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: day.$3.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(rControl),
                ),
                child: Column(
                  children: [
                    Text(
                      day.$1,
                      style: const TextStyle(
                        fontSize: 11,
                        color: textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      day.$2,
                      style: TextStyle(
                        color: day.$3,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
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
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              plan.recommendation,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              plan.tagline,
              style: const TextStyle(
                color: textMuted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            for (final block in plan.blocks) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(block.icon, color: plan.accent, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        block.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      block.duration,
                      style: const TextStyle(
                        color: textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: plan.accent,
                  foregroundColor: bg,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(rControl),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${plan.recommendation} ist vorgemerkt.')),
                  );
                },
                child: const Text(
                  'Für heute starten',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

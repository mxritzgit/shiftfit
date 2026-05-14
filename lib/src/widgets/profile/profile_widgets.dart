import 'package:flutter/material.dart';

import '../../models/lifetime_stats.dart';
import '../../models/shift_fit_plan.dart';
import '../../models/user_profile.dart';
import '../../models/weight_log.dart';
import '../../services/health_service.dart';
import '../../theme/app_colors.dart';
import '../common/basic_widgets.dart';
import 'profile_charts.dart';

class ProfileHero extends StatelessWidget {
  const ProfileHero({
    super.key,
    required this.name,
    required this.plan,
    required this.weekPlan,
    required this.workoutStreak,
  });

  final String name;
  final ShiftFitPlan plan;
  final List<String> weekPlan;
  final int workoutStreak;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'SF';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  String get _shiftPattern {
    final unique = <String>{};
    final order = <String>[];
    for (final s in weekPlan) {
      if (unique.add(s)) order.add(s);
    }
    return order.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      plan.accent.withValues(alpha: 0.28),
                      plan.accent.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: plan.accent.withValues(alpha: 0.4)),
                ),
                alignment: Alignment.center,
                child: Text(
                  _initials,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: plan.accent,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _shiftPattern.isEmpty
                          ? 'Schichtmuster anlegen'
                          : _shiftPattern,
                      style: const TextStyle(
                        color: textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Flexible(
                child: _HeroTag(
                  icon: Icons.local_fire_department_outlined,
                  label: workoutStreak == 0
                      ? 'Streak startet heute'
                      : '$workoutStreak Tage Streak',
                  color: workoutStreak == 0 ? textMuted : orange,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: _HeroTag(
                  icon: Icons.bolt_rounded,
                  label: plan.recommendation,
                  color: plan.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroTag extends StatelessWidget {
  const _HeroTag({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BodyStatsCard extends StatelessWidget {
  const BodyStatsCard({
    super.key,
    required this.profile,
    required this.log,
    required this.onLogWeight,
  });

  final UserProfile profile;
  final WeightLog log;
  final ValueChanged<double> onLogWeight;

  double get _bmi {
    final m = profile.heightCm / 100.0;
    if (m <= 0) return 0;
    final w = log.latest?.weightKg ?? profile.weightKg.toDouble();
    return w / (m * m);
  }

  @override
  Widget build(BuildContext context) {
    final latest = log.latest;
    final delta = log.trendDelta;
    final weightValue = latest?.weightKg ?? profile.weightKg.toDouble();
    final bmi = _bmi;
    final bmiLabel = BMIGaugePainter.labelFor(bmi);
    final bmiColor = BMIGaugePainter.colorFor(bmi);

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Körper',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              _InfoButton(
                onTap: () => _showBmiInfoSheet(context),
                tooltip: 'BMI-Erklärung',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      weightValue.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1.4,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'kg · aktuelles Gewicht',
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (delta != null) ...[
                      const SizedBox(height: 8),
                      _DeltaPill(delta: delta),
                    ],
                    const SizedBox(height: 14),
                    _BodyMetric(
                      icon: Icons.height_rounded,
                      label: '${profile.heightCm} cm',
                    ),
                    const SizedBox(height: 6),
                    _BodyMetric(
                      icon: Icons.cake_outlined,
                      label: '${profile.ageYears} J. · ${profile.sex.label}',
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 140,
                height: 110,
                child: CustomPaint(painter: BMIGaugePainter(bmi: bmi)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: bmiColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: bmiColor.withValues(alpha: 0.32)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: bmiColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'BMI $bmiLabel',
                    style: TextStyle(
                      color: bmiColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                Text(
                  bmi.toStringAsFixed(1),
                  style: TextStyle(
                    color: bmiColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const ValueKey('profile-log-weight'),
              onPressed: () => _promptWeight(context),
              icon: const Icon(Icons.add_rounded, size: 17),
              label: const Text(
                'Gewicht loggen',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: textPrimary,
                side: const BorderSide(color: hairline),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _promptWeight(BuildContext context) async {
    final result = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: surface,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) =>
          _ProfileWeightInputSheet(initial: log.latest?.weightKg ?? profile.weightKg.toDouble()),
    );
    if (result != null) onLogWeight(result);
  }

  static void _showBmiInfoSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: surface,
      showDragHandle: true,
      builder: (_) => const _BmiInfoSheet(),
    );
  }
}

class _BmiInfoSheet extends StatelessWidget {
  const _BmiInfoSheet();

  @override
  Widget build(BuildContext context) {
    final zones = [
      ('Untergewicht', '< 18.5', cyan),
      ('Normal', '18.5 – 24.9', lime),
      ('Übergewicht', '25.0 – 29.9', orange),
      ('Adipös', '≥ 30.0', pink),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BMI Orientierung',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Body Mass Index ist eine grobe Heuristik. Für Athleten und '
            'shiftarbeitende Körper ist die Tendenz interessanter als der '
            'absolute Wert.',
            style: TextStyle(color: textMuted, fontSize: 13, height: 1.45),
          ),
          const SizedBox(height: 16),
          for (final z in zones) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: z.$3.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: z.$3.withValues(alpha: 0.32)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: z.$3,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      z.$1,
                      style: TextStyle(
                        color: z.$3,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    z.$2,
                    style: const TextStyle(
                      color: textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileWeightInputSheet extends StatefulWidget {
  const _ProfileWeightInputSheet({required this.initial});

  final double initial;

  @override
  State<_ProfileWeightInputSheet> createState() =>
      _ProfileWeightInputSheetState();
}

class _ProfileWeightInputSheetState extends State<_ProfileWeightInputSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initial.toStringAsFixed(1),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gewicht loggen',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey('profile-weight-input'),
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Aktuelles Gewicht',
              suffixText: 'kg',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('profile-weight-save'),
              onPressed: () {
                final raw = _controller.text.trim().replaceAll(',', '.');
                final value = double.tryParse(raw);
                if (value != null && value > 0) Navigator.pop(context, value);
              },
              icon: const Icon(Icons.check_rounded, size: 17),
              label: const Text(
                'Speichern',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: lime,
                foregroundColor: bg,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeltaPill extends StatelessWidget {
  const _DeltaPill({required this.delta});

  final double delta;

  @override
  Widget build(BuildContext context) {
    final isFlat = delta.abs() < 0.05;
    final color = isFlat ? textMuted : (delta > 0 ? orange : cyan);
    final icon = isFlat
        ? Icons.remove_rounded
        : (delta > 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded);
    final label = isFlat
        ? 'stabil'
        : '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(1)} kg';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _BodyMetric extends StatelessWidget {
  const _BodyMetric({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: textMuted, size: 13),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class WeightHistoryCard extends StatelessWidget {
  const WeightHistoryCard({super.key, required this.log, required this.accent});

  final WeightLog log;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final hasData = log.entries.length >= 2;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Verlauf',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                hasData ? '${log.entries.length} Messungen' : '–',
                style: const TextStyle(
                  color: textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 130,
            child: CustomPaint(
              painter: WeightLineChartPainter(
                entries: log.entries,
                accent: accent,
              ),
              size: Size.infinite,
            ),
          ),
          if (hasData) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                _Caption(_formatShort(log.entries.first.timestamp)),
                const Spacer(),
                _Caption(_formatShort(log.entries.last.timestamp)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _formatShort(DateTime d) {
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return 'heute';
    }
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.';
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      ),
    );
  }
}

class GoalsOverviewCard extends StatelessWidget {
  const GoalsOverviewCard({
    super.key,
    required this.profile,
    required this.dailyKcal,
    required this.dailyWater,
    required this.dailySteps,
    required this.sleepMinutes,
    this.onEdit,
  });

  final UserProfile profile;
  final int dailyKcal;
  final int dailyWater;
  final int dailySteps;
  final int sleepMinutes;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final goals = <_Goal>[
      _Goal(
        label: 'Kcal',
        current: dailyKcal,
        target: profile.dailyKcalGoal,
        unit: 'kcal',
        color: orange,
        icon: Icons.local_fire_department_outlined,
      ),
      _Goal(
        label: 'Wasser',
        current: dailyWater,
        target: profile.dailyWaterGoalMl,
        unit: 'ml',
        color: cyan,
        icon: Icons.water_drop_outlined,
      ),
      _Goal(
        label: 'Schritte',
        current: dailySteps,
        target: profile.dailyStepsGoal,
        unit: '',
        color: lime,
        icon: Icons.directions_walk_outlined,
      ),
      _Goal(
        label: 'Schlaf',
        current: sleepMinutes,
        target: profile.dailySleepGoalMinutes,
        unit: 'min',
        color: pink,
        icon: Icons.bedtime_outlined,
      ),
    ];

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tagesziele',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              if (onEdit != null)
                TextButton(
                  key: const ValueKey('profile-edit-goals'),
                  onPressed: onEdit,
                  style: TextButton.styleFrom(
                    foregroundColor: textPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Anpassen',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [for (final g in goals) _GoalTile(goal: g)],
          ),
        ],
      ),
    );
  }
}

class _Goal {
  _Goal({
    required this.label,
    required this.current,
    required this.target,
    required this.unit,
    required this.color,
    required this.icon,
  });

  final String label;
  final int current;
  final int target;
  final String unit;
  final Color color;
  final IconData icon;

  double get ratio =>
      target <= 0 ? 0 : (current / target).clamp(0.0, 1.0).toDouble();
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({required this.goal});

  final _Goal goal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: hairline),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            height: 38,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(38, 38),
                  painter: MiniRingPainter(value: goal.ratio, color: goal.color),
                ),
                Icon(goal.icon, color: goal.color, size: 14),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.label,
                  style: const TextStyle(
                    color: textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${goal.current}/${goal.target}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
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

class ShiftDistributionCard extends StatelessWidget {
  const ShiftDistributionCard({super.key, required this.weekPlan});

  final List<String> weekPlan;

  Map<String, int> get _counts {
    final map = {'Früh': 0, 'Spät': 0, 'Nacht': 0, 'Frei': 0};
    for (final s in weekPlan) {
      if (map.containsKey(s)) map[s] = (map[s] ?? 0) + 1;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final counts = _counts;
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    final balance = (counts['Frei']! * 4 - counts['Nacht']! * 3 + 7)
        .clamp(0, 14)
        .toInt();
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Schicht-Mix',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 112,
                height: 112,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(112, 112),
                      painter: ShiftDonutPainter(counts: counts),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$total',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const Text(
                          'TAGE',
                          style: TextStyle(
                            color: textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShiftLegendRow(label: 'Früh', value: counts['Früh']!, color: lime),
                    const SizedBox(height: 8),
                    _ShiftLegendRow(label: 'Spät', value: counts['Spät']!, color: orange),
                    const SizedBox(height: 8),
                    _ShiftLegendRow(label: 'Nacht', value: counts['Nacht']!, color: pink),
                    const SizedBox(height: 8),
                    _ShiftLegendRow(label: 'Frei', value: counts['Frei']!, color: cyan),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: surfaceSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.balance_rounded, color: textMuted, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    counts['Nacht']! > 2
                        ? 'Nachtlastige Woche — plane einen Recovery-Tag früh ein.'
                        : counts['Frei']! >= 2
                            ? 'Genug Erholungsraum eingebaut.'
                            : 'Solide Mischung.',
                    style: const TextStyle(
                      color: textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
                Text(
                  '$balance/14',
                  style: TextStyle(
                    color: balance >= 9 ? lime : (balance >= 6 ? orange : pink),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
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

class _ShiftLegendRow extends StatelessWidget {
  const _ShiftLegendRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          '$value',
          style: TextStyle(
            color: value > 0 ? color : textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class LifetimeStatsCard extends StatelessWidget {
  const LifetimeStatsCard({super.key, required this.stats});

  final LifetimeStats stats;

  @override
  Widget build(BuildContext context) {
    final duration = stats.sessionDuration;
    final since = _formatSession(duration);
    final items = <_LifetimeTile>[
      _LifetimeTile(
        icon: Icons.fitness_center,
        color: lime,
        value: stats.workoutsCompleted.toString(),
        label: 'Workouts',
      ),
      _LifetimeTile(
        icon: Icons.restaurant_menu_rounded,
        color: orange,
        value: stats.mealsLogged.toString(),
        label: 'Mahlzeiten',
      ),
      _LifetimeTile(
        icon: Icons.water_drop_outlined,
        color: cyan,
        value: _formatWater(stats.waterTotalMl),
        label: 'Wasser',
      ),
      _LifetimeTile(
        icon: Icons.monitor_weight_outlined,
        color: pink,
        value: stats.weightLogs.toString(),
        label: 'Wiegen',
      ),
    ];
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Deine Session',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: surfaceSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  since,
                  style: const TextStyle(
                    color: textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.85,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: items,
          ),
        ],
      ),
    );
  }

  static String _formatSession(Duration d) {
    if (d.inMinutes < 1) return 'gerade gestartet';
    if (d.inMinutes < 60) return '${d.inMinutes} Min';
    final h = d.inHours;
    final rest = d.inMinutes % 60;
    if (rest == 0) return '${h}h';
    return '${h}h $rest Min';
  }

  static String _formatWater(int ml) {
    if (ml < 1000) return '$ml ml';
    return '${(ml / 1000).toStringAsFixed(1)} L';
  }
}

class _LifetimeTile extends StatelessWidget {
  const _LifetimeTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
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

class AchievementsGrid extends StatelessWidget {
  const AchievementsGrid({
    super.key,
    required this.stats,
    required this.workoutStreak,
    required this.weightLogs,
    required this.favoritesCount,
  });

  final LifetimeStats stats;
  final int workoutStreak;
  final int weightLogs;
  final int favoritesCount;

  @override
  Widget build(BuildContext context) {
    final achievements = <_Achievement>[
      _Achievement(
        icon: Icons.local_fire_department_rounded,
        title: 'Erster Streak',
        subtitle: workoutStreak >= 1 ? 'Erreicht' : '1 Workout durchziehen',
        color: orange,
        unlocked: workoutStreak >= 1,
      ),
      _Achievement(
        icon: Icons.calendar_view_week_rounded,
        title: '3er Streak',
        subtitle: workoutStreak >= 3
            ? 'Drei Tage am Stück'
            : '${(3 - workoutStreak).clamp(1, 3)} bis zum Badge',
        color: lime,
        unlocked: workoutStreak >= 3,
      ),
      _Achievement(
        icon: Icons.restaurant_rounded,
        title: 'Foodie',
        subtitle: stats.mealsLogged >= 5
            ? '${stats.mealsLogged} Mahlzeiten erfasst'
            : 'Logge 5 Mahlzeiten',
        color: pink,
        unlocked: stats.mealsLogged >= 5,
      ),
      _Achievement(
        icon: Icons.water_drop_rounded,
        title: 'Hydration',
        subtitle: stats.waterTotalMl >= 2000
            ? '${(stats.waterTotalMl / 1000).toStringAsFixed(1)} L erreicht'
            : '2 L Wasser tracken',
        color: cyan,
        unlocked: stats.waterTotalMl >= 2000,
      ),
      _Achievement(
        icon: Icons.monitor_weight_rounded,
        title: 'Tracker',
        subtitle: weightLogs >= 2
            ? 'Gewichtsverlauf aktiv'
            : 'Gewicht 2× loggen',
        color: lime,
        unlocked: weightLogs >= 2,
      ),
      _Achievement(
        icon: Icons.star_rounded,
        title: 'Favoriten',
        subtitle: favoritesCount >= 3
            ? '$favoritesCount Lieblings-Mahlzeiten'
            : '3 Mahlzeiten merken',
        color: orange,
        unlocked: favoritesCount >= 3,
      ),
    ];

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Achievements',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '${achievements.where((a) => a.unlocked).length}/${achievements.length}',
                style: const TextStyle(
                  color: textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.05,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [for (final a in achievements) _AchievementTile(data: a)],
          ),
        ],
      ),
    );
  }
}

class _Achievement {
  const _Achievement({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.unlocked,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool unlocked;
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.data});

  final _Achievement data;

  @override
  Widget build(BuildContext context) {
    final tint = data.unlocked ? data.color : textMuted;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: data.unlocked
            ? data.color.withValues(alpha: 0.10)
            : surfaceSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: data.unlocked
              ? data.color.withValues(alpha: 0.40)
              : hairline,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: data.unlocked ? 0.18 : 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, color: tint, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: data.unlocked ? textPrimary : textPrimary
                        .withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 10.5,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
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

class HealthConnectionCard extends StatelessWidget {
  const HealthConnectionCard({
    super.key,
    required this.state,
    required this.lastFetch,
    required this.onConnect,
    required this.onRefresh,
  });

  final HealthAuthState state;
  final DateTime? lastFetch;
  final VoidCallback onConnect;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final isGranted = state == HealthAuthState.granted;
    final isDenied = state == HealthAuthState.denied;
    final isUnsupported = state == HealthAuthState.unsupported;
    final color = isGranted
        ? lime
        : isDenied
            ? orange
            : textMuted;
    final subtitle = isGranted
        ? lastFetch != null
            ? 'Synchronisiert · ${_formatTime(lastFetch!)}'
            : 'Verbunden'
        : isDenied
            ? 'Berechtigung verweigert'
            : isUnsupported
                ? 'Auf diesem Gerät nicht aktiv'
                : 'Apple Health einrichten';

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isGranted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: color,
              size: 19,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Apple Health',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (isGranted)
            IconButton(
              key: const ValueKey('profile-health-refresh'),
              onPressed: onRefresh,
              tooltip: 'Aktualisieren',
              icon: const Icon(
                Icons.sync_rounded,
                color: textMuted,
                size: 20,
              ),
            )
          else if (!isUnsupported)
            FilledButton(
              key: const ValueKey('profile-health-connect'),
              onPressed: onConnect,
              style: FilledButton.styleFrom(
                backgroundColor: lime,
                foregroundColor: bg,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Verbinden',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  static String _formatTime(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 1) return 'gerade eben';
    if (diff.inMinutes < 60) return 'vor ${diff.inMinutes} Min';
    if (diff.inHours < 24) return 'vor ${diff.inHours}h';
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.';
  }
}

class ProfileActionsCard extends StatelessWidget {
  const ProfileActionsCard({
    super.key,
    required this.onEditProfile,
    required this.onResetDay,
    required this.onExport,
    required this.onAbout,
  });

  final VoidCallback onEditProfile;
  final VoidCallback onResetDay;
  final VoidCallback onExport;
  final VoidCallback onAbout;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          _ActionRow(
            icon: Icons.tune_rounded,
            color: lime,
            title: 'Profil & Ziele',
            subtitle: 'Körper, Schritte, Kcal, Schlaf',
            onTap: onEditProfile,
            keyValue: const ValueKey('profile-action-edit'),
          ),
          const _Divider(),
          _ActionRow(
            icon: Icons.restart_alt_rounded,
            color: orange,
            title: 'Tagesdaten zurücksetzen',
            subtitle: 'Heute neu starten',
            onTap: onResetDay,
            keyValue: const ValueKey('profile-action-reset'),
          ),
          const _Divider(),
          _ActionRow(
            icon: Icons.ios_share_rounded,
            color: cyan,
            title: 'Daten exportieren',
            subtitle: 'JSON Snapshot',
            onTap: onExport,
            keyValue: const ValueKey('profile-action-export'),
          ),
          const _Divider(),
          _ActionRow(
            icon: Icons.info_outline_rounded,
            color: textMuted,
            title: 'Über ShiftFit',
            subtitle: 'Version & Mitwirkende',
            onTap: onAbout,
            keyValue: const ValueKey('profile-action-about'),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.keyValue,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Key keyValue;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: keyValue,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: textMuted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: hairline,
    );
  }
}

class _InfoButton extends StatelessWidget {
  const _InfoButton({required this.onTap, required this.tooltip});

  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: surfaceSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.info_outline_rounded,
            color: textMuted,
            size: 15,
          ),
        ),
      ),
    );
  }
}

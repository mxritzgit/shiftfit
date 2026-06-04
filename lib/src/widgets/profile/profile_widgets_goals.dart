part of 'profile_widgets.dart';

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
        color: wellnessTone,
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
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
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
        borderRadius: BorderRadius.circular(rCard),
        border: Border.all(color: hairline),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            height: 38,
            // A11y: Fortschritts-Ring ansagen; der Wert daneben nennt die
            // absoluten Zahlen, hier reicht die Prozent-Erfuellung.
            child: Semantics(
              label: '${goal.label} Fortschritt',
              value: '${(goal.ratio * 100).round()}%',
              child: Stack(
                alignment: Alignment.center,
                children: [
                  RepaintBoundary(
                    child: CustomPaint(
                      size: const Size(38, 38),
                      painter:
                          MiniRingPainter(value: goal.ratio, color: goal.color),
                    ),
                  ),
                  Icon(goal.icon, color: goal.color, size: 14),
                ],
              ),
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
                    fontFeatures: [FontFeature.tabularFigures()],
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
    final map = {
      'Kraft': 0,
      'Muskelaufbau': 0,
      'Ausdauer': 0,
      'Recovery': 0,
      'Mobility': 0,
      'Frei': 0,
    };
    for (final s in weekPlan) {
      if (map.containsKey(s)) map[s] = (map[s] ?? 0) + 1;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final counts = _counts;
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    final balance = ((counts['Recovery']! + counts['Mobility']! + counts['Frei']!) * 3 -
            (counts['Kraft']! + counts['Muskelaufbau']!) + 7)
        .clamp(0, 14)
        .toInt();
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trainings-Mix',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
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
                    // A11y: Donut beschriftet -> Verteilung der Trainingstage.
                    Semantics(
                      label: 'Trainings-Mix',
                      value: '$total Tage geplant. Kraft ${counts['Kraft']!}, '
                          'Muskel ${counts['Muskelaufbau']!}, '
                          'Ausdauer ${counts['Ausdauer']!}, '
                          'Recovery ${counts['Recovery']! + counts['Mobility']! + counts['Frei']!}.',
                      child: RepaintBoundary(
                        child: CustomPaint(
                          size: const Size(112, 112),
                          painter: ShiftDonutPainter(counts: counts),
                        ),
                      ),
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
                            height: 1,
                            fontFeatures: [FontFeature.tabularFigures()],
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
                    _ShiftLegendRow(label: 'Kraft', value: counts['Kraft']!, color: lime),
                    const SizedBox(height: 8),
                    _ShiftLegendRow(label: 'Muskel', value: counts['Muskelaufbau']!, color: lime),
                    const SizedBox(height: 8),
                    _ShiftLegendRow(label: 'Ausdauer', value: counts['Ausdauer']!, color: orange),
                    const SizedBox(height: 8),
                    _ShiftLegendRow(label: 'Recovery', value: counts['Recovery']! + counts['Mobility']! + counts['Frei']!, color: cyan),
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
              borderRadius: BorderRadius.circular(rControl),
            ),
            child: Row(
              children: [
                const Icon(Icons.balance_rounded, color: textMuted, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    counts['Kraft']! + counts['Muskelaufbau']! > 3
                        ? 'Starke Woche: Recovery zwischen harte Reize legen.'
                        : counts['Recovery']! + counts['Mobility']! + counts['Frei']! >= 3
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
                    color: balance >= 9 ? lime : (balance >= 6 ? warning : danger),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    fontFeatures: const [FontFeature.tabularFigures()],
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
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

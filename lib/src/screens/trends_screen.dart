import 'package:flutter/material.dart';

import '../models/shift_fit_plan.dart';
import '../theme/app_colors.dart';
import '../widgets/common/basic_widgets.dart';
import '../widgets/shared/shiftfit_top_bar.dart';
import '../widgets/trends/trends_widgets.dart';
import '../widgets/week/week_widgets.dart';

class TrendsScreen extends StatelessWidget {
  const TrendsScreen({super.key, required this.plan, required this.weekPlan});

  final ShiftFitPlan plan;
  final List<String> weekPlan;

  int get streak => 5 + weekPlan.where((shift) => shift == 'Frei').length;

  int get loadBalance {
    final nights = weekPlan.where((shift) => shift == 'Nacht').length;
    final free = weekPlan.where((shift) => shift == 'Frei').length;
    return (74 + free * 4 - nights * 6).clamp(48, 94).toInt();
  }

  @override
  Widget build(BuildContext context) {
    final bars = [
      ('Mo', 0.72, lime),
      ('Di', 0.78, lime),
      ('Mi', 0.64, orange),
      ('Do', 0.69, orange),
      ('Fr', 0.54, pink),
      ('Sa', 0.58, pink),
      ('So', 0.86, cyan),
    ];

    return Column(
      key: const ValueKey('screen-trends'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShiftFitTopBar(plan: plan),
        const SizedBox(height: 24),
        AppCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StatusPill(label: 'Trends', color: lime),
              const SizedBox(height: 18),
              const Text(
                'Readiness bleibt\nsteuerbar.',
                style: TextStyle(
                  fontSize: 40,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Deine Muster zeigen, wann Training zieht und wann Recovery mehr bringt.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.64),
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                icon: Icons.favorite,
                title: 'Readiness',
                value: '${plan.recoveryScore}%',
                color: plan.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SummaryCard(
                icon: Icons.local_fire_department,
                title: 'Streak',
                value: '$streak Tage',
                color: orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SummaryCard(
          icon: Icons.balance,
          title: 'Belastungsbalance',
          value: '$loadBalance%',
          color: cyan,
        ),
        const SizedBox(height: 18),
        const SectionHeader(title: 'Readiness Verlauf', action: '7 Tage'),
        const SizedBox(height: 12),
        TrendBarsCard(bars: bars),
        const SizedBox(height: 18),
        const SectionHeader(title: 'Insights', action: 'Aktuell'),
        const SizedBox(height: 12),
        InsightsCard(plan: plan, loadBalance: loadBalance),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../models/shift_fit_plan.dart';
import '../../theme/app_colors.dart';
import '../common/basic_widgets.dart';

class TrendBarsCard extends StatelessWidget {
  const TrendBarsCard({super.key, required this.bars});

  final List<(String, double, Color)> bars;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      child: SizedBox(
        height: 150,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final bar in bars)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: bar.$2,
                          child: Container(
                            width: 18,
                            decoration: BoxDecoration(
                              color: bar.$3,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      bar.$1,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.62),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class InsightsCard extends StatelessWidget {
  const InsightsCard({super.key, required this.plan, required this.loadBalance});

  final ShiftFitPlan plan;
  final int loadBalance;

  @override
  Widget build(BuildContext context) {
    final insights = [
      plan.recoveryScore >= 80
          ? 'Heute ist genug Reserve für Kraft oder intensivere Intervalle da.'
          : 'Heute lohnt sich ein ruhiger Reset mehr als zusätzlicher Druck.',
      loadBalance >= 75
          ? 'Die Woche ist ausgewogen. Halte den Schlafanker stabil.'
          : 'Mehr Puffer einplanen: Mobility und kurze Spaziergänge statt Volumen.',
      'Koffein-Stopp und Lichtfenster bleiben deine stärksten Hebel.',
    ];

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          for (var i = 0; i < insights.length; i++) ...[
            Row(
              children: [
                Icon(i == 0 ? Icons.bolt : Icons.check_circle, color: i == 0 ? lime : cyan),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    insights[i],
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.68),
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (i != insights.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

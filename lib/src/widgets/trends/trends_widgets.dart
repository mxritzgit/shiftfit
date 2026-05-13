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
        height: 140,
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
                            width: 10,
                            decoration: BoxDecoration(
                              color: bar.$3.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      bar.$1,
                      style: const TextStyle(
                        color: textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
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
          ? 'Genug Reserve für Kraft oder intensivere Intervalle.'
          : 'Heute ruhiger Reset statt zusätzlicher Druck.',
      loadBalance >= 75
          ? 'Woche ist ausgewogen. Schlafanker stabil halten.'
          : 'Mehr Puffer einplanen: Mobility statt Volumen.',
      'Koffein-Stopp und Lichtfenster bleiben die stärksten Hebel.',
    ];

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          for (var i = 0; i < insights.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  i == 0 ? Icons.bolt : Icons.check_circle_outline,
                  color: i == 0 ? lime : cyan,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    insights[i],
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
            if (i != insights.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

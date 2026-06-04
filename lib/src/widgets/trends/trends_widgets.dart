import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../common/basic_widgets.dart';

/// Eine Balkensaeule im 7-Tage-Verlauf.
/// label  = Wochentags-Kuerzel aus dem echten Datum (Mo/Di/…)
/// ratio  = 0..1 Tages-Score (siehe TrendsScreen-Formel)
/// color  = Encoding-Farbe (lime fuer Workout-Tag, gedaempft sonst)
/// isToday hebt die heutige Saeule mit einem feinen Rand hervor.
class TrendBar {
  const TrendBar({
    required this.label,
    required this.ratio,
    required this.color,
    this.isToday = false,
  });

  final String label;
  final double ratio;
  final Color color;
  final bool isToday;
}

class TrendBarsCard extends StatelessWidget {
  const TrendBarsCard({super.key, required this.bars});

  final List<TrendBar> bars;

  /// A11y-Zusammenfassung der Saeulen: "Mo 40%, Di 80%, …".
  String get _semanticsValue => bars
      .map((b) => '${b.label} ${(b.ratio.clamp(0.0, 1.0) * 100).round()}%')
      .join(', ');

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A11y: der Balken-Chart traegt sonst keine Semantik -> 7-Tage-
          // Werte als ein gesprochenes Label buendeln, Deko-Innenleben aus
          // dem Baum nehmen.
          Semantics(
            label: '7-Tage-Verlauf',
            value: _semanticsValue,
            child: ExcludeSemantics(
              child: SizedBox(
            height: 128,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final bar in bars)
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        // Leerer Tag = niedriger, sichtbarer Sockel, nicht
                        // fehlend. Mindesthoehe 0.06.
                        heightFactor: bar.ratio.clamp(0.06, 1.0).toDouble(),
                        child: Container(
                          width: 11,
                          decoration: BoxDecoration(
                            color: bar.color.withValues(
                              alpha: bar.isToday ? 1.0 : 0.82,
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(rChip),
                              bottom: Radius.circular(2),
                            ),
                            border: bar.isToday
                                ? Border.all(color: lime, width: 1.4)
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
            ),
          ),
          // Feine Grundlinie verankert die Saeulen — Charts kleben nicht mehr
          // in der Luft (Edge-Cling-Fix, rein dekorativ).
          const SizedBox(height: 8),
          Container(height: 1, color: hairline),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final bar in bars)
                Expanded(
                  child: Text(
                    bar.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: bar.isToday ? textPrimary : textMuted,
                      fontSize: 11,
                      fontWeight:
                          bar.isToday ? FontWeight.w700 : FontWeight.w500,
                      letterSpacing: 0.2,
                      fontFeatures: const [FontFeature.tabularFigures()],
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

/// Ein berechneter Insight: Icon + Akzentfarbe + Text. Vom TrendsScreen aus
/// echten History-Mustern befuellt — keine Template-Konstanten mehr.
class TrendInsight {
  const TrendInsight({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;
}

class InsightsCard extends StatelessWidget {
  const InsightsCard({super.key, required this.insights});

  final List<TrendInsight> insights;

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) {
      return const AppCard(
        padding: EdgeInsets.all(16),
        child: Text(
          'Noch zu wenig Verlauf — log ein paar Tage, dann erscheinen hier Muster.',
          style: TextStyle(
            color: textMuted,
            fontSize: 13,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          for (var i = 0; i < insights.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  insights[i].icon,
                  color: insights[i].color,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    insights[i].text,
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

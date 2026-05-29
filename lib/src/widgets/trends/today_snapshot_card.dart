import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../common/basic_widgets.dart';

class SnapshotStat {
  const SnapshotStat({
    required this.label,
    required this.value,
    required this.color,
    required this.ratio,
    this.delta = 0,
  });

  final String label;
  final String value;
  final Color color;
  final double ratio;

  /// Optionales „vs. gestern"-Mikro-Signal: >0 hoch, <0 runter, 0 = neutral
  /// oder kein Vergleich verfuegbar. Wird als kleines ↑/↓ neben dem Label
  /// gezeigt (lime fuer hoch, danger fuer runter) — nur fuers Encoding.
  final int delta;
}

class TodaySnapshotCard extends StatelessWidget {
  const TodaySnapshotCard({super.key, required this.stats});

  final List<SnapshotStat> stats;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Heute',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < stats.length; i++) ...[
                Expanded(child: _Stat(stat: stats[i])),
                if (i != stats.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.stat});

  final SnapshotStat stat;

  @override
  Widget build(BuildContext context) {
    final double clamped = stat.ratio.clamp(0.0, 1.0).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          stat.value,
          style: TextStyle(
            color: stat.color,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Flexible(
              child: Text(
                stat.label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (stat.delta != 0) ...[
              const SizedBox(width: 3),
              Icon(
                stat.delta > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                size: 10,
                color: stat.delta > 0 ? lime : danger,
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(rPill),
          child: LinearProgressIndicator(
            value: clamped,
            minHeight: 3,
            backgroundColor: hairline,
            color: stat.color,
          ),
        ),
      ],
    );
  }
}

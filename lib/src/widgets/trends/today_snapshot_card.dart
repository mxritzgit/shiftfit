import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../common/basic_widgets.dart';

class SnapshotStat {
  const SnapshotStat({
    required this.label,
    required this.value,
    required this.color,
    required this.ratio,
  });

  final String label;
  final String value;
  final Color color;
  final double ratio;
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
          ),
        ),
        const SizedBox(height: 2),
        Text(
          stat.label,
          style: const TextStyle(
            color: textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
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

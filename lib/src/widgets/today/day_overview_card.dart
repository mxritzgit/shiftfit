import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../common/basic_widgets.dart';

class DayOverviewCard extends StatelessWidget {
  const DayOverviewCard({
    super.key,
    required this.waterRatio,
    required this.sleepRatio,
    required this.workoutRatio,
    required this.stepsRatio,
  });

  final double waterRatio;
  final double sleepRatio;
  final double workoutRatio;
  final double stepsRatio;

  double get overall =>
      ((waterRatio + sleepRatio + workoutRatio + stepsRatio) / 4)
          .clamp(0.0, 1.0)
          .toDouble();

  @override
  Widget build(BuildContext context) {
    final percent = (overall * 100).round();
    final waterPct = (waterRatio.clamp(0.0, 1.0) * 100).round();
    final sleepPct = (sleepRatio.clamp(0.0, 1.0) * 100).round();
    final planPct = (workoutRatio.clamp(0.0, 1.0) * 100).round();
    final stepsPct = (stepsRatio.clamp(0.0, 1.0) * 100).round();
    return AppCard(
      key: const ValueKey('day-overview-card'),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          // A11y: der reine Mal-Ring traegt sonst keine Bedeutung -> Gesamt-
          // wert + Segmente als Sprachausgabe verfuegbar machen.
          Semantics(
            label: 'Tagesüberblick',
            value: '$percent% gesamt. Wasser $waterPct%, Schlaf $sleepPct%, '
                'Plan $planPct%, Schritte $stepsPct%.',
            child: SizedBox(
              width: 84,
              height: 84,
              // RepaintBoundary: eigener Layer fuer den Tages-Ring.
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _DayRingPainter(
                  segments: [
                    (waterRatio.clamp(0.0, 1.0).toDouble(), cyan),
                    (sleepRatio.clamp(0.0, 1.0).toDouble(), wellnessTone),
                    (workoutRatio.clamp(0.0, 1.0).toDouble(), lime),
                    (stepsRatio.clamp(0.0, 1.0).toDouble(), orange),
                  ],
                  trackColor: hairline,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$percent%',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.6,
                          height: 1.0,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Tag',
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tagesüberblick',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 12),
                _LegendRow(
                  color: cyan,
                  label: 'Wasser',
                  ratio: waterRatio,
                ),
                const SizedBox(height: 7),
                _LegendRow(
                  color: wellnessTone,
                  label: 'Schlaf',
                  ratio: sleepRatio,
                ),
                const SizedBox(height: 7),
                _LegendRow(
                  color: lime,
                  label: 'Plan',
                  ratio: workoutRatio,
                ),
                const SizedBox(height: 7),
                _LegendRow(
                  color: orange,
                  label: 'Schritte',
                  ratio: stepsRatio,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.ratio,
  });

  final Color color;
  final String label;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    final percent = (ratio.clamp(0.0, 1.0) * 100).round();
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          '$percent%',
          style: const TextStyle(
            color: textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _DayRingPainter extends CustomPainter {
  _DayRingPainter({required this.segments, required this.trackColor});

  final List<(double, Color)> segments;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const stroke = 6.0;
    const gapDeg = 6.0;
    final segmentSpan = (360 - segments.length * gapDeg) / segments.length;

    for (var i = 0; i < segments.length; i++) {
      final radius = (size.width / 2) - stroke / 2 - i * (stroke + 1.5);
      if (radius <= 0) continue;
      final rect = Rect.fromCircle(center: center, radius: radius);
      final startDeg = -90 + i * (segmentSpan + gapDeg);
      final trackPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = trackColor;
      canvas.drawArc(
        rect,
        startDeg * math.pi / 180,
        segmentSpan * math.pi / 180,
        false,
        trackPaint,
      );
      final fillPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = segments[i].$2;
      canvas.drawArc(
        rect,
        startDeg * math.pi / 180,
        segmentSpan * segments[i].$1 * math.pi / 180,
        false,
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DayRingPainter oldDelegate) {
    return oldDelegate.segments != segments || oldDelegate.trackColor != trackColor;
  }
}

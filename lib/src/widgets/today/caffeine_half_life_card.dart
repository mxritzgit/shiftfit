import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/caffeine_entry.dart';
import '../../theme/app_colors.dart';
import '../common/basic_widgets.dart';

/// Caffeine half-life is ~5 hours. We model the active mg in the body as the
/// sum of exponential decay curves for each ingested dose.
class CaffeineHalfLifeCard extends StatelessWidget {
  const CaffeineHalfLifeCard({super.key, required this.day});

  final CaffeineDay day;

  static const double _halfLifeHours = 5.0;

  double _activeMgAt(DateTime moment) {
    double total = 0;
    for (final entry in day.entries) {
      final hours = moment.difference(entry.timestamp).inMinutes / 60.0;
      if (hours < 0) continue;
      final remaining = entry.mg * math.pow(0.5, hours / _halfLifeHours);
      total += remaining;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    if (day.entries.isEmpty) {
      return const SizedBox.shrink();
    }

    final now = DateTime.now();
    final samples = <double>[];
    for (var i = 0; i <= 24; i++) {
      final m = DateTime(now.year, now.month, now.day)
          .add(Duration(hours: i));
      samples.add(_activeMgAt(m));
    }

    final currentActive = _activeMgAt(now).round();
    final peak = samples.fold<double>(0, math.max);
    final maxScale = math.max(peak, 50.0);

    return AppCard(
      key: const ValueKey('caffeine-half-life-card'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Koffein im Blut',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Text(
                'aktiv $currentActive mg',
                style: const TextStyle(
                  color: orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Geschätzter Wirkstoffpegel über 24h · Halbwertszeit ~5h',
            style: TextStyle(
              color: textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            // RepaintBoundary: eigener Layer fuer die Halbwertszeit-Kurve.
            child: RepaintBoundary(
              child: CustomPaint(
                size: const Size.fromHeight(80),
                painter: _CurvePainter(
                  samples: samples,
                  maxScale: maxScale,
                  nowIndex: now.hour + now.minute / 60.0,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _AxisLabel('00'),
              _AxisLabel('06'),
              _AxisLabel('12'),
              _AxisLabel('18'),
              _AxisLabel('24'),
            ],
          ),
        ],
      ),
    );
  }
}

class _AxisLabel extends StatelessWidget {
  const _AxisLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: textMuted,
        fontSize: 10,
        fontWeight: FontWeight.w500,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }
}

class _CurvePainter extends CustomPainter {
  _CurvePainter({
    required this.samples,
    required this.maxScale,
    required this.nowIndex,
  });

  final List<double> samples;
  final double maxScale;
  final double nowIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) return;

    final path = Path();
    for (var i = 0; i < samples.length; i++) {
      final x = i / (samples.length - 1) * size.width;
      final y = size.height - (samples[i] / maxScale) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          orange.withValues(alpha: 0.30),
          orange.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = orange
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    final nowX = (nowIndex / 24) * size.width;
    final markerPaint = Paint()
      ..color = orange
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(nowX, 0),
      Offset(nowX, size.height),
      markerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CurvePainter oldDelegate) {
    return oldDelegate.samples != samples ||
        oldDelegate.maxScale != maxScale ||
        oldDelegate.nowIndex != nowIndex;
  }
}

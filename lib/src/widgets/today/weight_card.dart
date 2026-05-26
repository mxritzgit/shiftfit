import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/weight_log.dart';
import '../../theme/app_colors.dart';
import '../common/basic_widgets.dart';

class WeightCard extends StatelessWidget {
  const WeightCard({super.key, required this.log, required this.onLog});

  final WeightLog log;
  final ValueChanged<double> onLog;

  @override
  Widget build(BuildContext context) {
    final latest = log.latest;
    final delta = log.trendDelta;
    return AppCard(
      key: const ValueKey('weight-card'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: lime.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(rControl),
                ),
                child: const Icon(
                  Icons.monitor_weight_outlined,
                  color: lime,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Gewicht',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              TextButton(
                key: const ValueKey('weight-log-button'),
                onPressed: () => _logWeight(context),
                style: TextButton.styleFrom(
                  foregroundColor: lime,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Loggen',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      latest == null
                          ? '–'
                          : latest.weightKg.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1,
                        color: lime,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      latest == null
                          ? 'Noch nichts geloggt'
                          : 'kg · ${_formatDate(latest.timestamp)}',
                      style: const TextStyle(
                        color: textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (delta != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} kg vs. erste Messung',
                        style: TextStyle(
                          color: delta.abs() < 0.001 ? textMuted : (delta > 0 ? orange : cyan),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (log.entries.length >= 2)
                SizedBox(
                  width: 100,
                  height: 50,
                  child: CustomPaint(
                    painter: _WeightSparkline(entries: log.entries),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _logWeight(BuildContext context) async {
    final result = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: surface,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _WeightInputSheet(initial: log.latest?.weightKg ?? 78.0),
    );
    if (result != null) {
      onLog(result);
    }
  }

  static String _formatDate(DateTime d) {
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return 'heute';
    }
    if (d.year == now.year && d.month == now.month && d.day == now.day - 1) {
      return 'gestern';
    }
    return '${d.day}.${d.month}.';
  }
}

class _WeightSparkline extends CustomPainter {
  _WeightSparkline({required this.entries});

  final List<WeightLogEntry> entries;

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.length < 2) return;
    final values = entries.map((e) => e.weightKg).toList();
    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final range = math.max(maxV - minV, 0.5);

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = i / (values.length - 1) * size.width;
      final y = size.height - ((values[i] - minV) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paint = Paint()
      ..color = lime
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);

    final dot = Paint()..color = lime;
    final lastX = size.width;
    final lastY = size.height -
        ((values.last - minV) / range) * size.height;
    canvas.drawCircle(Offset(lastX, lastY), 2.5, dot);
  }

  @override
  bool shouldRepaint(covariant _WeightSparkline oldDelegate) =>
      oldDelegate.entries != entries;
}

class _WeightInputSheet extends StatefulWidget {
  const _WeightInputSheet({required this.initial});

  final double initial;

  @override
  State<_WeightInputSheet> createState() => _WeightInputSheetState();
}

class _WeightInputSheetState extends State<_WeightInputSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial.toStringAsFixed(1));
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
            key: const ValueKey('weight-input'),
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Aktuelles Gewicht',
              suffixText: 'kg',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('weight-save'),
              onPressed: () {
                final raw = _controller.text.trim().replaceAll(',', '.');
                final value = double.tryParse(raw);
                if (value != null && value > 0) {
                  Navigator.pop(context, value);
                }
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
                  borderRadius: BorderRadius.circular(rControl),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

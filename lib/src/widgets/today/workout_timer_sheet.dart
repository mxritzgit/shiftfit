import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/plan_block.dart';
import '../../theme/app_colors.dart';

Future<bool?> showWorkoutTimerSheet(
  BuildContext context, {
  required PlanBlock block,
  required Color accent,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: surface,
    showDragHandle: true,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    builder: (sheetContext) => _WorkoutTimerSheet(block: block, accent: accent),
  );
}

class _WorkoutTimerSheet extends StatefulWidget {
  const _WorkoutTimerSheet({required this.block, required this.accent});

  final PlanBlock block;
  final Color accent;

  @override
  State<_WorkoutTimerSheet> createState() => _WorkoutTimerSheetState();
}

class _WorkoutTimerSheetState extends State<_WorkoutTimerSheet> {
  Timer? _ticker;
  late int _remainingSeconds;
  late int _totalSeconds;
  bool _running = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _totalSeconds = _parseMinutes(widget.block.duration) * 60;
    _remainingSeconds = _totalSeconds;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  int _parseMinutes(String duration) {
    final match = RegExp(r'\d+').firstMatch(duration);
    return match == null ? 5 : int.parse(match.group(0)!);
  }

  void _toggle() {
    if (_finished) return;
    setState(() => _running = !_running);
    if (_running) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            _finished = true;
            _running = false;
            _ticker?.cancel();
          }
        });
      });
    } else {
      _ticker?.cancel();
    }
  }

  void _reset() {
    _ticker?.cancel();
    setState(() {
      _remainingSeconds = _totalSeconds;
      _running = false;
      _finished = false;
    });
  }

  void _finish(bool markDone) {
    _ticker?.cancel();
    Navigator.of(context).pop(markDone);
  }

  String _formatTime(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalSeconds <= 0
        ? 0.0
        : (1 - _remainingSeconds / _totalSeconds).clamp(0.0, 1.0).toDouble();
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        4,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: widget.accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  widget.block.icon,
                  color: widget.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.block.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.block.description,
                      style: const TextStyle(
                        color: textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    backgroundColor: hairline,
                    color: widget.accent,
                    strokeCap: StrokeCap.round,
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _finished ? 'fertig' : _formatTime(_remainingSeconds),
                        key: const ValueKey('workout-timer-remaining'),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _finished
                            ? 'Block geschafft'
                            : _running ? 'läuft' : 'pausiert',
                        style: const TextStyle(
                          color: textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const ValueKey('workout-timer-reset'),
                  onPressed: _reset,
                  icon: const Icon(Icons.restart_alt_rounded, size: 17),
                  label: const Text(
                    'Zurück',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textPrimary,
                    side: const BorderSide(color: hairline),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  key: const ValueKey('workout-timer-toggle'),
                  onPressed: _finished ? null : _toggle,
                  icon: Icon(
                    _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 18,
                  ),
                  label: Text(
                    _finished ? 'Fertig' : (_running ? 'Pause' : 'Start'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.accent,
                    foregroundColor: bg,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              key: const ValueKey('workout-timer-finish'),
              onPressed: () => _finish(_finished),
              icon: Icon(
                _finished
                    ? Icons.check_circle_rounded
                    : Icons.close_rounded,
                size: 17,
              ),
              label: Text(
                _finished ? 'Block abhaken' : 'Schließen ohne abhaken',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              style: TextButton.styleFrom(
                foregroundColor: _finished ? widget.accent : textMuted,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

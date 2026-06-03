import 'package:flutter/material.dart';

import '../../models/sleep_entry.dart';
import '../../theme/app_colors.dart';

Future<SleepEntry?> showSleepLogSheet(
  BuildContext context, {
  SleepEntry? initial,
}) {
  return showModalBottomSheet<SleepEntry>(
    context: context,
    backgroundColor: surface,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _SleepLogSheet(initial: initial),
  );
}

class _SleepLogSheet extends StatefulWidget {
  const _SleepLogSheet({this.initial});

  final SleepEntry? initial;

  @override
  State<_SleepLogSheet> createState() => _SleepLogSheetState();
}

class _SleepLogSheetState extends State<_SleepLogSheet> {
  late int bedtime;
  late int wake;
  late int quality;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    bedtime = initial?.bedtimeMinutes ?? 22 * 60 + 30;
    wake = initial?.wakeMinutes ?? 6 * 60 + 30;
    quality = initial?.quality ?? 4;
  }

  String _label(int minutes) {
    final h = (minutes ~/ 60) % 24;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  Future<void> _pickTime({
    required int currentMinutes,
    required ValueChanged<int> onPicked,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: (currentMinutes ~/ 60) % 24,
        minute: currentMinutes % 60,
      ),
    );
    if (picked != null) {
      onPicked(picked.hour * 60 + picked.minute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tentative = SleepEntry(
      date: DateTime.now(),
      bedtimeMinutes: bedtime,
      wakeMinutes: wake,
      quality: quality,
    );
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
            'Schlaf loggen',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Dauer: ${tentative.durationLabel}',
            style: const TextStyle(
              color: textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _TimeField(
                  label: 'Ins Bett',
                  value: _label(bedtime),
                  keyValue: const ValueKey('sleep-pick-bedtime'),
                  onTap: () => _pickTime(
                    currentMinutes: bedtime,
                    onPicked: (v) => setState(() => bedtime = v),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TimeField(
                  label: 'Aufgestanden',
                  value: _label(wake),
                  keyValue: const ValueKey('sleep-pick-wake'),
                  onTap: () => _pickTime(
                    currentMinutes: wake,
                    onPicked: (v) => setState(() => wake = v),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'QUALITÄT',
            style: TextStyle(
              color: textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    key: ValueKey('sleep-quality-$i'),
                    onTap: () => setState(() => quality = i),
                    borderRadius: BorderRadius.circular(rControl),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: i <= quality
                            ? orange.withValues(alpha: 0.18)
                            : surfaceSoft,
                        borderRadius: BorderRadius.circular(rControl),
                      ),
                      child: Icon(
                        i <= quality ? Icons.star_rounded : Icons.star_border_rounded,
                        color: i <= quality ? orange : textMuted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('sleep-save-button'),
              onPressed: () => Navigator.pop(context, tentative),
              icon: const Icon(Icons.check_rounded, size: 17),
              label: const Text(
                'Speichern',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: wellnessTone,
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

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
    required this.keyValue,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final Key keyValue;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: keyValue,
      onTap: onTap,
      borderRadius: BorderRadius.circular(rControl),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: surfaceSoft,
          borderRadius: BorderRadius.circular(rControl),
          border: Border.all(color: hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

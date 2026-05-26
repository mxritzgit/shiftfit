import 'package:flutter/material.dart';

import '../../models/sleep_entry.dart';
import '../../theme/app_colors.dart';
import '../common/basic_widgets.dart';

class WaterTrackerCard extends StatelessWidget {
  const WaterTrackerCard({
    super.key,
    required this.intakeMl,
    required this.goalMl,
    required this.onAdd,
    required this.onReset,
  });

  final int intakeMl;
  final int goalMl;
  final ValueChanged<int> onAdd;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final double ratio = goalMl <= 0
        ? 0.0
        : (intakeMl / goalMl).clamp(0.0, 1.0).toDouble();
    final percent = (ratio * 100).round();

    return AppCard(
      key: const ValueKey('water-tracker-card'),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cyan.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(rControl),
                ),
                child: const Icon(Icons.water_drop_outlined, color: cyan, size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Trinkwasser',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                key: const ValueKey('water-reset-button'),
                onPressed: intakeMl == 0 ? null : onReset,
                tooltip: 'Zurücksetzen',
                icon: const Icon(Icons.refresh_rounded, size: 18, color: textMuted),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$intakeMl',
                key: const ValueKey('water-intake-amount'),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                  color: cyan,
                ),
              ),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  'ml',
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '$percent% · $goalMl ml Ziel',
                style: const TextStyle(
                  color: textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(rPill),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: hairline,
              color: cyan,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _WaterAddButton(
                  amount: 200,
                  onTap: () => onAdd(200),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _WaterAddButton(
                  amount: 330,
                  onTap: () => onAdd(330),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _WaterAddButton(
                  amount: 500,
                  onTap: () => onAdd(500),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WaterAddButton extends StatelessWidget {
  const _WaterAddButton({required this.amount, required this.onTap});

  final int amount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey('water-add-$amount'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(rControl),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: surfaceSoft,
          borderRadius: BorderRadius.circular(rControl),
          border: Border.all(color: cyan.withValues(alpha: 0.22)),
        ),
        alignment: Alignment.center,
        child: Text(
          '+$amount',
          style: const TextStyle(
            color: cyan,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class SleepLogCard extends StatelessWidget {
  const SleepLogCard({
    super.key,
    required this.lastEntry,
    required this.goalMinutes,
    required this.onLog,
  });

  final SleepEntry? lastEntry;
  final int goalMinutes;
  final VoidCallback onLog;

  @override
  Widget build(BuildContext context) {
    final goalH = (goalMinutes / 60).toStringAsFixed(goalMinutes % 60 == 0 ? 0 : 1);
    return AppCard(
      key: const ValueKey('sleep-log-card'),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: wellnessTone.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(rControl),
            ),
            child: const Icon(Icons.bedtime_outlined, color: wellnessTone, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Schlaf',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                if (lastEntry == null)
                  Text(
                    'Noch nichts geloggt · Ziel ${goalH}h',
                    style: const TextStyle(
                      color: textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else
                  Row(
                    children: [
                      Text(
                        lastEntry!.durationLabel,
                        key: const ValueKey('sleep-last-duration'),
                        style: const TextStyle(
                          color: wellnessTone,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${lastEntry!.bedtimeLabel} → ${lastEntry!.wakeLabel}',
                        style: const TextStyle(
                          color: textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _QualityStars(quality: lastEntry!.quality),
                    ],
                  ),
              ],
            ),
          ),
          TextButton(
            key: const ValueKey('sleep-log-button'),
            onPressed: onLog,
            style: TextButton.styleFrom(
              foregroundColor: wellnessTone,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
    );
  }
}

class _QualityStars extends StatelessWidget {
  const _QualityStars({required this.quality});

  final int quality;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= quality ? Icons.star_rounded : Icons.star_border_rounded,
            size: 11,
            color: i <= quality ? orange : textMuted,
          ),
      ],
    );
  }
}

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
              letterSpacing: 0.8,
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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

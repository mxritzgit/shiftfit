import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

enum QuickAddKind { water, caffeine, steps, sleep }

class QuickAddResult {
  const QuickAddResult({required this.kind, this.amount});

  final QuickAddKind kind;
  final int? amount;
}

Future<QuickAddResult?> showQuickAddSheet(BuildContext context) {
  return showModalBottomSheet<QuickAddResult>(
    context: context,
    backgroundColor: surface,
    showDragHandle: true,
    builder: (sheetContext) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Schnell loggen',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 12),
            _QuickRow(
              icon: Icons.water_drop_outlined,
              label: 'Wasser',
              color: cyan,
              options: const [200, 330, 500],
              suffix: 'ml',
              keyPrefix: 'quick-water',
              onPick: (amt) => Navigator.pop(
                sheetContext,
                QuickAddResult(kind: QuickAddKind.water, amount: amt),
              ),
            ),
            const SizedBox(height: 10),
            _QuickRow(
              icon: Icons.coffee_outlined,
              label: 'Koffein',
              color: orange,
              options: const [60, 95, 80],
              suffix: 'mg',
              keyPrefix: 'quick-caffeine',
              onPick: (amt) => Navigator.pop(
                sheetContext,
                QuickAddResult(kind: QuickAddKind.caffeine, amount: amt),
              ),
            ),
            const SizedBox(height: 10),
            _QuickRow(
              icon: Icons.directions_walk_rounded,
              label: 'Schritte',
              color: lime,
              options: const [500, 1500, 3000],
              suffix: '',
              keyPrefix: 'quick-steps',
              onPick: (amt) => Navigator.pop(
                sheetContext,
                QuickAddResult(kind: QuickAddKind.steps, amount: amt),
              ),
            ),
            const SizedBox(height: 14),
            TextButton.icon(
              key: const ValueKey('quick-add-sleep'),
              onPressed: () => Navigator.pop(
                sheetContext,
                const QuickAddResult(kind: QuickAddKind.sleep),
              ),
              icon: const Icon(Icons.bedtime_outlined, size: 17, color: pink),
              label: const Text(
                'Schlaf loggen',
                style: TextStyle(
                  color: pink,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _QuickRow extends StatelessWidget {
  const _QuickRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.options,
    required this.suffix,
    required this.onPick,
    required this.keyPrefix,
  });

  final IconData icon;
  final String label;
  final Color color;
  final List<int> options;
  final String suffix;
  final ValueChanged<int> onPick;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 6,
            children: [
              for (final option in options)
                InkWell(
                  key: ValueKey('$keyPrefix-$option'),
                  onTap: () => onPick(option),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: surfaceSoft,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: color.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Text(
                      '+$option${suffix.isNotEmpty ? ' $suffix' : ''}',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../models/caffeine_entry.dart';
import '../../theme/app_colors.dart';
import '../common/basic_widgets.dart';

class CaffeineCard extends StatelessWidget {
  const CaffeineCard({
    super.key,
    required this.day,
    required this.shift,
    required this.onAdd,
    required this.onReset,
  });

  final CaffeineDay day;
  final String shift;
  final ValueChanged<int> onAdd;
  final VoidCallback onReset;

  /// Recommended caffeine cutoff in minutes-of-day per shift. Late caffeine
  /// kills the next sleep cycle, so we surface a soft warning.
  int get cutoffMinutes {
    switch (shift) {
      case 'Nacht':
        return 26 * 60; // 02:00 next day, allow late
      case 'Spät':
        return 18 * 60;
      case 'Frei':
        return 14 * 60;
      default:
        return 13 * 60;
    }
  }

  bool get afterCutoff {
    final now = DateTime.now();
    final mins = now.hour * 60 + now.minute;
    return mins > cutoffMinutes;
  }

  @override
  Widget build(BuildContext context) {
    final mins = cutoffMinutes;
    final cutoffH = (mins ~/ 60) % 24;
    final cutoffM = mins % 60;
    final cutoffLabel = '${cutoffH.toString().padLeft(2, '0')}:${cutoffM.toString().padLeft(2, '0')}';

    return AppCard(
      key: const ValueKey('caffeine-card'),
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
                  color: orange.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(rControl),
                ),
                child: const Icon(
                  Icons.coffee_outlined,
                  color: orange,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Koffein',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              IconButton(
                key: const ValueKey('caffeine-reset-button'),
                onPressed: day.entries.isEmpty ? null : onReset,
                tooltip: 'Zurücksetzen',
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: textMuted,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${day.totalMg}',
                key: const ValueKey('caffeine-total-mg'),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                  height: 1.0,
                  color: orange,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Text(
                  'mg',
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${day.cups} Tasse${day.cups == 1 ? '' : 'n'} · Stopp $cutoffLabel',
                style: const TextStyle(
                  color: textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          if (afterCutoff && day.entries.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: wellnessTone.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(rControl),
              ),
              child: const Text(
                'Spät dran — Schlaf könnte schlechter werden.',
                style: TextStyle(
                  color: wellnessTone,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _CaffeineButton(
                  label: 'Espresso',
                  mg: 60,
                  onTap: () => onAdd(60),
                  keyValue: const ValueKey('caffeine-add-espresso'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CaffeineButton(
                  label: 'Kaffee',
                  mg: 95,
                  onTap: () => onAdd(95),
                  keyValue: const ValueKey('caffeine-add-coffee'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CaffeineButton(
                  label: 'Energy',
                  mg: 80,
                  onTap: () => onAdd(80),
                  keyValue: const ValueKey('caffeine-add-energy'),
                ),
              ),
            ],
          ),
          if (day.entries.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var i = 0; i < day.entries.length; i++)
                  Chip(
                    key: ValueKey('caffeine-entry-$i'),
                    backgroundColor: surfaceSoft,
                    side: BorderSide.none,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 0,
                    ),
                    label: Text(
                      '${day.entries[i].clockLabel} · ${day.entries[i].mg}mg',
                      style: const TextStyle(
                        color: textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CaffeineButton extends StatelessWidget {
  const _CaffeineButton({
    required this.label,
    required this.mg,
    required this.onTap,
    required this.keyValue,
  });

  final String label;
  final int mg;
  final VoidCallback onTap;
  final Key keyValue;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: keyValue,
      onTap: onTap,
      borderRadius: BorderRadius.circular(rControl),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: surfaceSoft,
          borderRadius: BorderRadius.circular(rControl),
          border: Border.all(color: orange.withValues(alpha: 0.22)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: orange,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '+${mg}mg',
              style: const TextStyle(
                color: textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

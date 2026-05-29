import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';

/// Bottom-sheet quick-log affordances for the Today tab.
///
/// These follow the locked add/edit pattern (entity tap -> modal bottom sheet,
/// `rSheet` radius, lime/data-tone accents, no FABs). They return the chosen
/// amount via `Navigator.pop`; the caller wires the result into the Home
/// handlers (`_addWater`, `_setSteps`, ...). The widgets here own no state that
/// must persist — persistence lives in the Home layer.

/// Water quick-add sheet. Opened when the "Wasser" tracker stat is tapped.
/// Returns the chosen ml amount (positive) or null if dismissed. Use the
/// returned value with the Home `_addWater(int ml)` handler.
Future<int?> showWaterQuickAddSheet(
  BuildContext context, {
  required int intakeMl,
  required int goalMl,
}) {
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: surface,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) =>
        _WaterQuickAddSheet(intakeMl: intakeMl, goalMl: goalMl),
  );
}

class _WaterQuickAddSheet extends StatelessWidget {
  const _WaterQuickAddSheet({required this.intakeMl, required this.goalMl});

  final int intakeMl;
  final int goalMl;

  static const List<int> _presets = [200, 330, 500];

  @override
  Widget build(BuildContext context) {
    final double ratio =
        goalMl <= 0 ? 0.0 : (intakeMl / goalMl).clamp(0.0, 1.0).toDouble();
    final percent = (ratio * 100).round();

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
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: cyan.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(rControl),
                ),
                child: const Icon(
                  Icons.water_drop_outlined,
                  color: cyan,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Wasser loggen',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$intakeMl',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                  height: 1.0,
                  color: cyan,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(bottom: 3),
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
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  fontFeatures: [FontFeature.tabularFigures()],
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
          const SizedBox(height: 18),
          Row(
            children: [
              for (var i = 0; i < _presets.length; i++) ...[
                Expanded(
                  child: _WaterPresetButton(
                    amount: _presets[i],
                    keyValue: ValueKey('water-quick-add-${_presets[i]}'),
                    onTap: () => Navigator.pop(context, _presets[i]),
                  ),
                ),
                if (i != _presets.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _WaterPresetButton extends StatelessWidget {
  const _WaterPresetButton({
    required this.amount,
    required this.onTap,
    required this.keyValue,
  });

  final int amount;
  final VoidCallback onTap;
  final Key keyValue;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: keyValue,
      onTap: onTap,
      borderRadius: BorderRadius.circular(rControl),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: surfaceSoft,
          borderRadius: BorderRadius.circular(rControl),
          border: Border.all(color: cyan.withValues(alpha: 0.22)),
        ),
        child: Text(
          '+$amount ml',
          style: const TextStyle(
            color: cyan,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

/// Steps quick-set sheet. Opened when the "Schritte" tracker stat is tapped.
/// Returns the absolute step count to set, or null if dismissed. Use with the
/// Home `_setSteps(int)` handler.
Future<int?> showStepsQuickSetSheet(
  BuildContext context, {
  required int steps,
}) {
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: surface,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => _StepsQuickSetSheet(initial: steps),
  );
}

class _StepsQuickSetSheet extends StatefulWidget {
  const _StepsQuickSetSheet({required this.initial});

  final int initial;

  @override
  State<_StepsQuickSetSheet> createState() => _StepsQuickSetSheetState();
}

class _StepsQuickSetSheetState extends State<_StepsQuickSetSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial.toString());
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
            'Schritte setzen',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey('steps-quick-input'),
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Schritte heute',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('steps-quick-save'),
              onPressed: () {
                final value = int.tryParse(_controller.text.trim()) ?? 0;
                Navigator.pop(context, value);
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

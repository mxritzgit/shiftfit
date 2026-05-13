import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../common/basic_widgets.dart';

class StepsCard extends StatelessWidget {
  const StepsCard({
    super.key,
    required this.steps,
    required this.goal,
    required this.onAdd,
    required this.onSet,
  });

  final int steps;
  final int goal;
  final ValueChanged<int> onAdd;
  final ValueChanged<int> onSet;

  @override
  Widget build(BuildContext context) {
    final double ratio = goal <= 0
        ? 0.0
        : (steps / goal).clamp(0.0, 1.0).toDouble();
    final percent = (ratio * 100).round();

    return AppCard(
      key: const ValueKey('steps-card'),
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
                  color: lime.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.directions_walk_rounded,
                  color: lime,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Schritte',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              TextButton(
                key: const ValueKey('steps-edit-button'),
                onPressed: () => _editSteps(context),
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
                  'Setzen',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$steps',
                key: const ValueKey('steps-count'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                  color: lime,
                ),
              ),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Text(
                  'Schritte',
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '$percent% · $goal Ziel',
                style: const TextStyle(
                  color: textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: hairline,
              color: lime,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StepsButton(
                  amount: 500,
                  onTap: () => onAdd(500),
                  keyValue: const ValueKey('steps-add-500'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StepsButton(
                  amount: 1500,
                  onTap: () => onAdd(1500),
                  keyValue: const ValueKey('steps-add-1500'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StepsButton(
                  amount: 3000,
                  onTap: () => onAdd(3000),
                  keyValue: const ValueKey('steps-add-3000'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _editSteps(BuildContext context) async {
    final result = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: surface,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _StepsEditSheet(initial: steps),
    );
    if (result != null) {
      onSet(result);
    }
  }
}

class _StepsButton extends StatelessWidget {
  const _StepsButton({
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: surfaceSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: lime.withValues(alpha: 0.22)),
        ),
        child: Text(
          '+$amount',
          style: const TextStyle(
            color: lime,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _StepsEditSheet extends StatefulWidget {
  const _StepsEditSheet({required this.initial});

  final int initial;

  @override
  State<_StepsEditSheet> createState() => _StepsEditSheetState();
}

class _StepsEditSheetState extends State<_StepsEditSheet> {
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
            key: const ValueKey('steps-input'),
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
              key: const ValueKey('steps-save'),
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
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class SegmentedOptions extends StatelessWidget {
  const SegmentedOptions({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
  });

  final List<String> options;
  final String selectedValue;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: surfaceSoft,
        borderRadius: BorderRadius.circular(rControl),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: OptionPill(
                key: ValueKey('option-$option'),
                label: option,
                selected: option == selectedValue,
                onTap: () => onSelected(option),
              ),
            ),
        ],
      ),
    );
  }
}

class OptionPill extends StatelessWidget {
  const OptionPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? surface : Colors.transparent,
          borderRadius: BorderRadius.circular(rChip),
          border: selected
              ? const Border.fromBorderSide(BorderSide(color: hairline))
              : null,
          boxShadow: selected ? cardShadow : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? textPrimary : textMuted,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class ShiftChoiceChip extends StatelessWidget {
  const ShiftChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(rControl),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.55) : hairline,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : textPrimary.withValues(alpha: 0.78),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

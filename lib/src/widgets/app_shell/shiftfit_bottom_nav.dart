import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class ShiftFitBottomNav extends StatelessWidget {
  const ShiftFitBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_rounded, 'Heute'),
      (Icons.calendar_month_rounded, 'Woche'),
      (Icons.insights_rounded, 'Trends'),
      (Icons.local_fire_department_rounded, 'Kcal'),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.96),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: TextButton.icon(
                key: ValueKey('nav-${items[i].$2}'),
                onPressed: () => onSelected(i),
                icon: Icon(items[i].$1, size: 20),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(items[i].$2),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: i == selectedIndex ? lime : Colors.white54,
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

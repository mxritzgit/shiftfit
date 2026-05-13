import 'package:flutter/material.dart';

import '../../models/shift_fit_plan.dart';
import '../../theme/app_colors.dart';

class ShiftFitTopBar extends StatelessWidget {
  const ShiftFitTopBar({super.key, required this.plan, this.onSettingsPressed});

  final ShiftFitPlan plan;
  final VoidCallback? onSettingsPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ShiftFit',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Schichtarbeit. Training. Recovery.',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (onSettingsPressed != null)
          IconButton(
            key: const ValueKey('topbar-settings'),
            onPressed: onSettingsPressed,
            tooltip: 'Einstellungen',
            icon: const Icon(Icons.tune_rounded, size: 20, color: textMuted),
            visualDensity: VisualDensity.compact,
          ),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: plan.accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.nightlight_round, color: plan.accent, size: 18),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../models/shift_fit_plan.dart';

class ShiftFitTopBar extends StatelessWidget {
  const ShiftFitTopBar({super.key, required this.plan});

  final ShiftFitPlan plan;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ShiftFit',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'Schichtarbeit. Training. Recovery.',
              style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: plan.accent.withValues(alpha: 0.45)),
          ),
          child: CircleAvatar(
            radius: 22,
            backgroundColor: plan.accent.withValues(alpha: 0.16),
            child: Icon(Icons.nightlight_round, color: plan.accent, size: 22),
          ),
        ),
      ],
    );
  }
}

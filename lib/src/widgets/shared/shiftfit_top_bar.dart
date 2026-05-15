import 'package:flutter/material.dart';

import '../../models/shift_fit_plan.dart';
import '../../theme/app_colors.dart';

class ShiftFitTopBar extends StatelessWidget {
  const ShiftFitTopBar({
    super.key,
    required this.plan,
    this.onSettingsPressed,
    this.onProfilePressed,
    this.profileInitial,
  });

  final ShiftFitPlan plan;
  final VoidCallback? onSettingsPressed;
  final VoidCallback? onProfilePressed;
  final String? profileInitial;

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
                'FitPilot',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'FitnessPlan. Training. Recovery.',
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
        _AvatarBadge(
          plan: plan,
          initial: profileInitial,
          onTap: onProfilePressed,
        ),
      ],
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.plan, this.initial, this.onTap});

  final ShiftFitPlan plan;
  final String? initial;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final showInitial = onTap != null && (initial != null && initial!.isNotEmpty);
    final badge = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            plan.accent.withValues(alpha: 0.20),
            plan.accent.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: plan.accent.withValues(alpha: 0.35)),
      ),
      alignment: Alignment.center,
      child: showInitial
          ? Text(
              initial!,
              style: TextStyle(
                color: plan.accent,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            )
          : Icon(Icons.fitness_center_rounded, color: plan.accent, size: 18),
    );

    if (onTap == null) return badge;
    return Material(
      key: const ValueKey('topbar-profile'),
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: badge,
      ),
    );
  }
}

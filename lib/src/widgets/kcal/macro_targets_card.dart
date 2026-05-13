import 'package:flutter/material.dart';

import '../../models/macro_progress.dart';
import '../../models/user_profile.dart';
import '../../theme/app_colors.dart';
import '../common/basic_widgets.dart';

class MacroTargetsCard extends StatelessWidget {
  const MacroTargetsCard({
    super.key,
    required this.progress,
    required this.profile,
  });

  final MacroProgress progress;
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final double kcalRatio = profile.dailyKcalGoal <= 0
        ? 0.0
        : (progress.kcal / profile.dailyKcalGoal).clamp(0.0, 1.0).toDouble();
    final remainingKcal = (profile.dailyKcalGoal - progress.kcal).clamp(
      -99999,
      99999,
    );

    return AppCard(
      key: const ValueKey('macro-targets-card'),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tagesziele',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                remainingKcal >= 0
                    ? '$remainingKcal kcal übrig'
                    : '${-remainingKcal} kcal über',
                style: TextStyle(
                  color: remainingKcal >= 0 ? lime : orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: kcalRatio,
              minHeight: 6,
              backgroundColor: hairline,
              color: orange,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '${progress.kcal} / ${profile.dailyKcalGoal} kcal',
                style: const TextStyle(
                  color: textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MacroDial(
                  label: 'Protein',
                  current: progress.proteinG,
                  goal: profile.proteinGoalG.toDouble(),
                  color: lime,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MacroDial(
                  label: 'Carbs',
                  current: progress.carbsG,
                  goal: profile.carbsGoalG.toDouble(),
                  color: cyan,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MacroDial(
                  label: 'Fett',
                  current: progress.fatG,
                  goal: profile.fatGoalG.toDouble(),
                  color: pink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroDial extends StatelessWidget {
  const _MacroDial({
    required this.label,
    required this.current,
    required this.goal,
    required this.color,
  });

  final String label;
  final double current;
  final double goal;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final double ratio = goal <= 0 ? 0.0 : (current / goal).clamp(0.0, 1.0).toDouble();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: surfaceSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 46,
            height: 46,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: ratio,
                  strokeWidth: 4,
                  backgroundColor: hairline,
                  color: color,
                  strokeCap: StrokeCap.round,
                ),
                Text(
                  '${(ratio * 100).round()}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${current.toStringAsFixed(current >= 10 ? 0 : 1)} / ${goal.toStringAsFixed(0)} g',
            style: const TextStyle(
              color: textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

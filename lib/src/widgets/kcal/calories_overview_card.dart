import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/logged_meal.dart';
import '../../models/macro_progress.dart';
import '../../models/user_profile.dart';
import '../../theme/app_colors.dart';
import '../common/basic_widgets.dart';

class CaloriesOverviewCard extends StatelessWidget {
  const CaloriesOverviewCard({
    super.key,
    required this.dailyConsumedKcal,
    required this.kcalGoal,
    this.burnedKcal = 0,
  });

  final int dailyConsumedKcal;
  final int kcalGoal;
  final int burnedKcal;

  @override
  Widget build(BuildContext context) {
    final goal = kcalGoal <= 0 ? 1 : kcalGoal;
    final eaten = dailyConsumedKcal.clamp(0, 99999).toInt();
    final burned = burnedKcal.clamp(0, 99999).toInt();
    final adjustedGoal = goal + burned;
    final remaining = (adjustedGoal - eaten).clamp(-99999, 99999).toInt();
    final progress = (eaten / adjustedGoal).clamp(0.0, 1.0);
    final remainingColor = remaining >= 0 ? lime : danger;

    return AppCard(
      key: const ValueKey('analyse-daily-kcal-card'),
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ÜBRIGE KALORIEN',
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _formatThousands(remaining),
                      style: TextStyle(
                        color: remainingColor,
                        fontSize: 46,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                        letterSpacing: -1.8,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'kcal',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      remaining >= 0
                          ? '$eaten von $adjustedGoal kcal'
                          : '${-remaining} kcal über Ziel',
                      style: const TextStyle(
                        color: textMuted,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 108,
                height: 108,
                child: _ProgressRing(
                  progress: progress,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${(progress * 100).round()}%',
                        style: const TextStyle(
                          color: textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'des Ziels',
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.gps_fixed_rounded,
                  iconColor: lime,
                  label: 'ZIEL',
                  value: _formatThousands(goal),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  icon: Icons.restaurant_rounded,
                  iconColor: lime,
                  label: 'GEGESSEN',
                  combinedKcal: '$eaten kcal',
                  combinedKcalKey: const ValueKey('analyse-daily-kcal-total'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  icon: Icons.local_fire_department_outlined,
                  iconColor: cyan,
                  label: 'VERBRANNT',
                  value: burned == 0 ? '—' : _formatThousands(burned),
                  showKcalSuffix: burned != 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.value,
    this.showKcalSuffix = true,
    this.combinedKcal,
    this.combinedKcalKey,
  }) : assert(value != null || combinedKcal != null);

  final IconData icon;
  final Color iconColor;
  final String label;
  final String? value;
  final bool showKcalSuffix;
  final String? combinedKcal;
  final Key? combinedKcalKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
      decoration: BoxDecoration(
        color: surfaceSoft,
        borderRadius: BorderRadius.circular(rControl),
        border: Border.all(color: hairline),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 12),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (combinedKcal != null)
            Text(
              combinedKcal!,
              key: combinedKcalKey,
              style: const TextStyle(
                color: textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            )
          else ...[
            Text(
              value!,
              style: const TextStyle(
                color: textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (showKcalSuffix)
              const Text(
                'kcal',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 9,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.progress, required this.child});

  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RingPainter(progress: progress),
      child: Center(child: child),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 10.0;
    final rect = Offset(stroke / 2, stroke / 2) &
        Size(size.width - stroke, size.height - stroke);
    final center = rect.center;
    final radius = rect.width / 2;

    final track = Paint()
      ..color = surfaceSoft
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    const startAngle = -math.pi / 2;
    final sweep = 2 * math.pi * progress;

    final gradient = SweepGradient(
      startAngle: 0,
      endAngle: 2 * math.pi,
      transform: const GradientRotation(-math.pi / 2),
      // Energy ring is a single brand metric: lime only, soft fade-in start.
      colors: [lime.withValues(alpha: 0.45), lime, lime, lime],
      stops: const [0.0, 0.45, 0.85, 1.0],
    );

    final arc = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweep, false, arc);

    const dotAngle = startAngle;
    final dotPos = Offset(
      center.dx + radius * math.cos(dotAngle),
      center.dy + radius * math.sin(dotAngle),
    );
    final dotPaint = Paint()..color = lime.withValues(alpha: 0.9);
    canvas.drawCircle(dotPos, stroke / 2 + 2, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}

class MacrosOverviewCard extends StatelessWidget {
  const MacrosOverviewCard({
    super.key,
    required this.progress,
    required this.profile,
    this.onDetailsPressed,
  });

  final MacroProgress progress;
  final UserProfile profile;
  final VoidCallback? onDetailsPressed;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      key: const ValueKey('macro-targets-card'),
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'MAKROS HEUTE',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              if (onDetailsPressed != null)
                InkWell(
                  onTap: onDetailsPressed,
                  borderRadius: BorderRadius.circular(rChip),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Row(
                      children: const [
                        Text(
                          'Details ansehen',
                          style: TextStyle(
                            color: lime,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(Icons.chevron_right_rounded, color: lime, size: 14),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _MacroTile(
                  label: 'PROTEIN',
                  current: progress.proteinG,
                  goal: profile.proteinGoalG.toDouble(),
                  color: lime,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MacroTile(
                  label: 'KOHLENH.',
                  current: progress.carbsG,
                  goal: profile.carbsGoalG.toDouble(),
                  color: cyan,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MacroTile(
                  label: 'FETT',
                  current: progress.fatG,
                  goal: profile.fatGoalG.toDouble(),
                  color: macroFat,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroTile extends StatelessWidget {
  const _MacroTile({
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
    final ratio = goal <= 0 ? 0.0 : (current / goal).clamp(0.0, 1.0).toDouble();
    final currentLabel = current >= 10
        ? current.round().toString()
        : current.toStringAsFixed(1).replaceAll('.', ',');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$currentLabel g',
                    style: const TextStyle(
                      color: textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '/ ${goal.toStringAsFixed(0)} g',
                    style: const TextStyle(
                      color: textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 30,
              height: 30,
              child: _MiniRing(
                progress: ratio,
                color: color,
                label: '${(ratio * 100).round()}%',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(rPill),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 3,
            backgroundColor: surfaceSoft,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _MiniRing extends StatelessWidget {
  const _MiniRing({
    required this.progress,
    required this.color,
    required this.label,
  });

  final double progress;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: const Size.square(30),
          painter: _MiniRingPainter(progress: progress, color: color),
        ),
        Text(
          label,
          style: const TextStyle(
            color: textPrimary,
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MiniRingPainter extends CustomPainter {
  _MiniRingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 4.0;
    final rect = Offset(stroke / 2, stroke / 2) &
        Size(size.width - stroke, size.height - stroke);

    final track = Paint()
      ..color = surfaceSoft
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(rect.center, rect.width / 2, track);

    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniRingPainter old) =>
      old.progress != progress || old.color != color;
}

class MealsTodayCard extends StatelessWidget {
  const MealsTodayCard({
    super.key,
    required this.meals,
    this.onMealTap,
  });

  final List<LoggedMeal> meals;
  final ValueChanged<MealSlot>? onMealTap;

  @override
  Widget build(BuildContext context) {
    final totals = <MealSlot, int>{
      for (final slot in MealSlot.values) slot: 0,
    };
    for (final meal in meals) {
      totals[meal.slot] = (totals[meal.slot] ?? 0) + meal.result.caloriesKcal;
    }
    final overallTotal = totals.values.fold<int>(0, (sum, v) => sum + v);

    return AppCard(
      key: const ValueKey('kcal-meals-today-card'),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text(
                'MAHLZEITEN HEUTE',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              Spacer(),
              Text(
                'kcal',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          for (final slot in MealSlot.values)
            _MealRow(
              key: ValueKey('meal-slot-${slot.name}'),
              slot: slot,
              kcal: totals[slot] ?? 0,
              onTap: onMealTap == null ? null : () => onMealTap!(slot),
            ),
          const Divider(color: hairline, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const Text(
                  'GESAMT',
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatThousands(overallTotal),
                  style: const TextStyle(
                    color: textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'kcal',
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MealRow extends StatelessWidget {
  const _MealRow({
    super.key,
    required this.slot,
    required this.kcal,
    required this.onTap,
  });

  final MealSlot slot;
  final int kcal;
  final VoidCallback? onTap;

  IconData get _icon => switch (slot) {
        MealSlot.breakfast => Icons.wb_sunny_outlined,
        MealSlot.lunch => Icons.light_mode_outlined,
        MealSlot.dinner => Icons.nights_stay_outlined,
        MealSlot.snack => Icons.cookie_outlined,
      };

  Color get _color => switch (slot) {
        MealSlot.breakfast => orange,
        MealSlot.lunch => lime,
        MealSlot.dinner => slotDinner,
        MealSlot.snack => cyan,
      };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(rControl),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(_icon, color: _color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                slot.label,
                style: const TextStyle(
                  color: textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              kcal.toString(),
              style: TextStyle(
                color: kcal > 0 ? textPrimary : textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: textMuted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

String _formatThousands(int n) {
  final negative = n < 0;
  final s = n.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final fromEnd = s.length - i;
    buf.write(s[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) buf.write('.');
  }
  return negative ? '-${buf.toString()}' : buf.toString();
}

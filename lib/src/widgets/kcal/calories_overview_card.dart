import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

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
    required this.macroProgress,
    required this.profile,
  });

  final int dailyConsumedKcal;
  final int kcalGoal;
  final int burnedKcal;
  final MacroProgress macroProgress;
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final goal = kcalGoal <= 0 ? 1 : kcalGoal;
    final eaten = dailyConsumedKcal.clamp(0, 99999).toInt();
    final burned = burnedKcal.clamp(0, 99999).toInt();
    final adjustedGoal = goal + burned;
    final remaining = (adjustedGoal - eaten).clamp(-99999, 99999).toInt();
    final progress = (eaten / adjustedGoal).clamp(0.0, 1.0);
    final remainingColor = remaining >= 0 ? forgeLime : danger;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : double.infinity;
        final compact = maxHeight < 270;
        final tight = maxHeight < 225;
        final padding = EdgeInsets.all(tight ? 12 : (compact ? 14 : 18));
        final ringSize = tight ? 60.0 : (compact ? 72.0 : 92.0);
        final remainingSize = tight ? 32.0 : (compact ? 38.0 : 46.0);
        final titleGap = tight ? 4.0 : (compact ? 6.0 : 8.0);
        final statsGap = tight ? 6.0 : (compact ? 8.0 : 12.0);
        final macrosGap = tight ? 8.0 : (compact ? 10.0 : 14.0);
        final showSubtitle = !tight;

        final content = Column(
          mainAxisAlignment: compact
              ? MainAxisAlignment.start
              : MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'VERBLEIBENDE KCAL',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: titleGap),
                      Text(
                        _formatThousands(remaining),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: remainingColor,
                          fontSize: remainingSize,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                          letterSpacing: compact ? -1.4 : -1.8,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      SizedBox(height: tight ? 1 : 2),
                      Text(
                        'kcal',
                        style: TextStyle(
                          color: textMuted,
                          fontSize: tight ? 12 : 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                      if (showSubtitle) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Ziel: ${_formatThousands(adjustedGoal)} kcal',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: textMuted,
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: compact ? 8 : 10),
                SizedBox(
                  width: ringSize,
                  height: ringSize,
                  child: _ProgressRing(
                    progress: progress,
                    strokeWidth: compact ? 8 : 10,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(progress * 100).round()}%',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: tight ? 15 : (compact ? 17 : 19),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: tight ? 0 : 2),
                        Text(
                          'des Ziels',
                          style: TextStyle(
                            color: textMuted,
                            fontSize: tight ? 8.5 : 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: statsGap),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    icon: Icons.gps_fixed_rounded,
                    iconColor: forgeLime,
                    label: 'ZIEL',
                    value: _formatThousands(goal),
                    compact: compact,
                    tight: tight,
                  ),
                ),
                SizedBox(width: compact ? 6 : 8),
                Expanded(
                  child: _StatTile(
                    icon: Icons.restaurant_rounded,
                    iconColor: forgeLime,
                    label: 'GEGESSEN',
                    combinedKcal: '$eaten kcal',
                    combinedKcalKey: const ValueKey('analyse-daily-kcal-total'),
                    compact: compact,
                    tight: tight,
                  ),
                ),
                SizedBox(width: compact ? 6 : 8),
                Expanded(
                  child: _StatTile(
                    icon: Icons.local_fire_department_outlined,
                    iconColor: cyan,
                    label: 'VERBRANNT',
                    value: burned == 0 ? '—' : _formatThousands(burned),
                    showKcalSuffix: burned != 0,
                    compact: compact,
                    tight: tight,
                  ),
                ),
              ],
            ),
            SizedBox(height: macrosGap),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _InlineMacroBar(
                    label: 'Proteine',
                    current: macroProgress.proteinG,
                    goal: profile.proteinGoalG.toDouble(),
                    color: forgeLime,
                    compact: compact,
                    tight: tight,
                  ),
                ),
                SizedBox(width: compact ? 8 : 12),
                Expanded(
                  child: _InlineMacroBar(
                    label: 'Kohlenhydrate',
                    current: macroProgress.carbsG,
                    goal: profile.carbsGoalG.toDouble(),
                    color: macroCarbs,
                    compact: compact,
                    tight: tight,
                  ),
                ),
                SizedBox(width: compact ? 8 : 12),
                Expanded(
                  child: _InlineMacroBar(
                    label: 'Fette',
                    current: macroProgress.fatG,
                    goal: profile.fatGoalG.toDouble(),
                    color: macroFat,
                    compact: compact,
                    tight: tight,
                  ),
                ),
              ],
            ),
          ],
        );

        return _GlassPanel(
          key: const ValueKey('analyse-daily-kcal-card'),
          padding: padding,
          child: content,
        );
      },
    );
  }
}

/// Translucent „Glass"-Panel im Stitch-„FORGE"-Stil: weicher forgeLime-Glow
/// oben-rechts, darüber ein BackdropFilter-Blur und ein transluzenter Fill mit
/// Hairline-Rand. Ersetzt die solide [AppCard] NUR für die Kalorienkarte.
class _GlassPanel extends StatelessWidget {
  const _GlassPanel({
    super.key,
    required this.child,
    required this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(rCard)),
        boxShadow: cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(rCard),
        child: Stack(
          children: [
            // 1) Dekorativer, weicher forgeLime-Glow oben-rechts.
            Positioned(
              top: -50,
              right: -40,
              child: IgnorePointer(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: forgeLime.withValues(alpha: 0.10),
                    ),
                  ),
                ),
              ),
            ),
            // 2) Transluzentes Panel: Backdrop-Blur + Glass-Fill + Hairline.
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: forgeGlassFill,
                    borderRadius: BorderRadius.circular(rCard),
                    border: Border.all(color: forgeGlassBorder),
                  ),
                ),
              ),
            ),
            // 3) Inhalt.
            Padding(
              padding: padding,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

/// Schmaler Inline-Makro-Balken (Label + aktuell/ziel-g + dünner Balken).
class _InlineMacroBar extends StatelessWidget {
  const _InlineMacroBar({
    required this.label,
    required this.current,
    required this.goal,
    required this.color,
    this.compact = false,
    this.tight = false,
  });

  final String label;
  final double current;
  final double goal;
  final Color color;
  final bool compact;
  final bool tight;

  @override
  Widget build(BuildContext context) {
    final ratio = goal <= 0 ? 0.0 : (current / goal).clamp(0.0, 1.0).toDouble();
    final currentG = current.round();
    final goalG = goal.round();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: compact ? 10.5 : 11.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: tight ? 3 : 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(rPill),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: surfaceSoft,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        SizedBox(height: tight ? 3 : 4),
        Text(
          '$currentG/${goalG}g',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
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
    this.compact = false,
    this.tight = false,
  }) : assert(value != null || combinedKcal != null);

  final IconData icon;
  final Color iconColor;
  final String label;
  final String? value;
  final bool showKcalSuffix;
  final String? combinedKcal;
  final Key? combinedKcalKey;
  final bool compact;
  final bool tight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: tight ? 6 : (compact ? 7 : 11),
        horizontal: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: surfaceSoft,
        borderRadius: BorderRadius.circular(rControl),
        border: Border.all(color: hairline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: compact ? 10 : 12),
              SizedBox(width: compact ? 3 : 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textMuted,
                    fontSize: compact ? 8.2 : 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: compact ? 0.35 : 0.6,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: tight ? 2 : 4),
          if (combinedKcal != null)
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                combinedKcal!,
                key: combinedKcalKey,
                maxLines: 1,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: compact ? 12.5 : 14,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            )
          else ...[
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value!,
                maxLines: 1,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: compact ? 13 : 15,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            if (showKcalSuffix && !tight)
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
  const _ProgressRing({
    required this.progress,
    required this.child,
    this.strokeWidth = 10,
  });

  final double progress;
  final Widget child;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RingPainter(progress: progress, strokeWidth: strokeWidth),
      child: Center(child: child),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.strokeWidth});

  final double progress;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = strokeWidth;
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
      // Energy ring is a single brand metric: forgeLime only, soft fade-in start.
      colors: [forgeLime.withValues(alpha: 0.45), forgeLime, forgeLime, forgeLime],
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
    final dotPaint = Paint()..color = forgeLime.withValues(alpha: 0.9);
    canvas.drawCircle(dotPos, stroke / 2 + 2, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.strokeWidth != strokeWidth;
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : double.infinity;
        final compact = maxHeight < 150;
        final tight = maxHeight < 120;
        final padding = EdgeInsets.all(tight ? 14 : (compact ? 16 : 18));
        final tileGap = tight ? 8.0 : (compact ? 10.0 : 12.0);

        final header = Row(
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
                          color: forgeLime,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right_rounded, color: forgeLime, size: 14),
                    ],
                  ),
                ),
              ),
          ],
        );

        final tiles = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _MacroTile(
                label: 'PROTEIN',
                current: progress.proteinG,
                goal: profile.proteinGoalG.toDouble(),
                color: forgeLime,
                compact: compact,
                tight: tight,
              ),
            ),
            SizedBox(width: tileGap),
            Expanded(
              child: _MacroTile(
                label: 'KOHLENH.',
                current: progress.carbsG,
                goal: profile.carbsGoalG.toDouble(),
                color: cyan,
                compact: compact,
                tight: tight,
              ),
            ),
            SizedBox(width: tileGap),
            Expanded(
              child: _MacroTile(
                label: 'FETT',
                current: progress.fatG,
                goal: profile.fatGoalG.toDouble(),
                color: macroFat,
                compact: compact,
                tight: tight,
              ),
            ),
          ],
        );

        // Edge-cling fix: header sits at the top, the macro tiles claim the
        // remaining height and stay vertically centred — no dead band between
        // a top-pinned title and bottom-pinned tiles.
        final boundedHeight = constraints.hasBoundedHeight;
        return AppCard(
          key: const ValueKey('macro-targets-card'),
          padding: padding,
          child: Column(
            mainAxisSize: boundedHeight ? MainAxisSize.max : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header,
              if (boundedHeight)
                Expanded(
                  child: Center(child: tiles),
                )
              else ...[
                SizedBox(height: tight ? 10 : 12),
                tiles,
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MacroTile extends StatelessWidget {
  const _MacroTile({
    required this.label,
    required this.current,
    required this.goal,
    required this.color,
    this.compact = false,
    this.tight = false,
  });

  final String label;
  final double current;
  final double goal;
  final Color color;
  final bool compact;
  final bool tight;

  @override
  Widget build(BuildContext context) {
    final ratio = goal <= 0 ? 0.0 : (current / goal).clamp(0.0, 1.0).toDouble();
    final currentLabel = current >= 10
        ? current.round().toString()
        : current.toStringAsFixed(1).replaceAll('.', ',');
    final ringSize = tight ? 26.0 : 30.0;
    final labelGap = tight ? 7.0 : (compact ? 8.0 : 10.0);
    final barGap = tight ? 8.0 : (compact ? 9.0 : 11.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
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
        SizedBox(height: labelGap),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$currentLabel g',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                      letterSpacing: -0.2,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '/ ${goal.toStringAsFixed(0)} g',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(
              width: ringSize,
              height: ringSize,
              child: _MiniRing(
                progress: ratio,
                color: color,
                label: '${(ratio * 100).round()}%',
              ),
            ),
          ],
        ),
        SizedBox(height: barGap),
        ClipRRect(
          borderRadius: BorderRadius.circular(rPill),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 4,
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
        Positioned.fill(
          child: CustomPaint(
            painter: _MiniRingPainter(progress: progress, color: color),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: textPrimary,
            fontSize: 8,
            fontWeight: FontWeight.w700,
            fontFeatures: [FontFeature.tabularFigures()],
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
    final overallTotal =
        meals.fold<int>(0, (sum, m) => sum + m.result.caloriesKcal);
    // Kopie absteigend nach Zeitpunkt sortieren — Original nicht mutieren.
    final sorted = List<LoggedMeal>.of(meals)
      ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));

    final header = Row(
      children: [
        const Text(
          'Verlauf',
          style: TextStyle(
            color: textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const Spacer(),
        if (sorted.isNotEmpty)
          Text(
            '${_formatThousands(overallTotal)} kcal',
            style: const TextStyle(
              color: textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
      ],
    );

    return AppCard(
      key: const ValueKey('kcal-meals-today-card'),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 8),
          Expanded(
            child: sorted.isEmpty
                ? const _HistoryEmptyState()
                : ListView.builder(
                    key: const ValueKey('food-history'),
                    padding: EdgeInsets.zero,
                    itemCount: sorted.length,
                    itemBuilder: (context, index) {
                      final meal = sorted[index];
                      return _HistoryEntry(
                        key: ValueKey('food-history-entry-$index'),
                        meal: meal,
                        onTap: onMealTap == null
                            ? null
                            : () => onMealTap!(meal.slot),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _HistoryEmptyState extends StatelessWidget {
  const _HistoryEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Noch nichts geloggt',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Tippe oben auf KI-Scan, Barcode oder Suche.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textMuted,
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryEntry extends StatelessWidget {
  const _HistoryEntry({
    super.key,
    required this.meal,
    required this.onTap,
  });

  final LoggedMeal meal;
  final VoidCallback? onTap;

  IconData get _slotIcon => switch (meal.slot) {
        MealSlot.breakfast => Icons.bakery_dining_rounded,
        MealSlot.lunch => Icons.lunch_dining_rounded,
        MealSlot.dinner => Icons.dinner_dining_rounded,
        MealSlot.snack => Icons.coffee_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final grams = meal.result.estimatedGrams;
    final amount = grams > 0 ? '~$grams g' : '1 Portion';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(rControl),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: surfaceSoft,
                borderRadius: BorderRadius.circular(rControl),
              ),
              child: Icon(_slotIcon, color: textMuted, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    meal.result.mealName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${meal.slot.label} • $amount',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${meal.result.caloriesKcal}',
                  style: const TextStyle(
                    color: forgeLime,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const Text(
                  'kcal',
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
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

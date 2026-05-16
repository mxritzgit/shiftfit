// main.dart
//
// Shiftfit – Kalorien-Screen (alles in einer Datei).
// Drop-in: einfach als lib/main.dart speichern und `flutter run`.
//
// Keine externen Packages nötig.

import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() => runApp(const FitnessApp());

// ---------------------------------------------------------------------------
// App
// ---------------------------------------------------------------------------

class FitnessApp extends StatelessWidget {
  const FitnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shiftfit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bg,
        // Optional: globale Schriftart setzen
        // fontFamily: 'Inter',
      ),
      home: const CaloriesScreen(),
    );
  }
}

// ---------------------------------------------------------------------------
// Farben
// ---------------------------------------------------------------------------

class AppColors {
  static const bg = Color(0xFF0B0D12);
  static const card = Color(0xFF14171F);
  static const cardSoft = Color(0xFF1A1E27);
  static const stroke = Color(0xFF232733);

  static const textPrimary = Color(0xFFF2F4F8);
  static const textSecondary = Color(0xFF8A91A1);
  static const textMuted = Color(0xFF5B6273);

  // Akzentfarben aus dem Mock
  static const blue = Color(0xFF5B8DFF);       // Protein / Hauptakzent
  static const blueBright = Color(0xFF49B6FF); // große Zahl 640
  static const teal = Color(0xFF4FE0C4);       // Kohlenhydrate / Ring-Ende
  static const violet = Color(0xFF7C5BFF);     // Ring-Mitte
  static const magenta = Color(0xFFE15BD0);    // Fett
  static const orange = Color(0xFFFFB454);     // Frühstück
  static const yellow = Color(0xFFFFD66B);     // Mittagessen
  static const sunset = Color(0xFFFF8A6B);     // Abendessen
  static const lime = Color(0xFFB6E36B);       // Snacks
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class CaloriesScreen extends StatelessWidget {
  const CaloriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const _Header(),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              sliver: SliverList.list(
                children: const [
                  _CaloriesCard(
                    remaining: 640,
                    goal: 2200,
                    eaten: 1280,
                    burned: 280,
                  ),
                  SizedBox(height: 16),
                  _MacrosCard(
                    protein: _Macro('PROTEIN', 112, 160, AppColors.blue),
                    carbs: _Macro('KOHLENHYDRATE', 156, 220, AppColors.teal),
                    fat: _Macro('FETT', 48, 73, AppColors.magenta),
                  ),
                  SizedBox(height: 16),
                  _MealsCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
        child: Row(
          children: [
            const Text(
              'Kalorien',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 30,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const Spacer(),
            _CircleIconButton(
              icon: Icons.calendar_today_outlined,
              onTap: () {},
            ),
            const SizedBox(width: 8),
            _CircleIconButton(
              icon: Icons.more_horiz,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 24,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: AppColors.card,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 18),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card-Container
// ---------------------------------------------------------------------------

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsets.all(18)});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.stroke, width: 1),
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Übrige Kalorien
// ---------------------------------------------------------------------------

class _CaloriesCard extends StatelessWidget {
  const _CaloriesCard({
    required this.remaining,
    required this.goal,
    required this.eaten,
    required this.burned,
  });

  final int remaining;
  final int goal;
  final int eaten;
  final int burned;

  @override
  Widget build(BuildContext context) {
    final progress = (eaten / goal).clamp(0.0, 1.0);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Linke Spalte: Übrige Kalorien
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ÜBRIGE KALORIEN',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      remaining.toString(),
                      style: const TextStyle(
                        color: AppColors.blueBright,
                        fontSize: 56,
                        fontWeight: FontWeight.w700,
                        height: 1.0,
                        letterSpacing: -1.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'kcal',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Du machst das großartig!\nBleib fokussiert. 🚀',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              // Rechte Spalte: Ring
              SizedBox(
                width: 150,
                height: 150,
                child: _ProgressRing(
                  progress: progress,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${(progress * 100).round()}%',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Deines Ziels',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.gps_fixed,
                  iconColor: AppColors.violet,
                  label: 'ZIEL',
                  value: _fmt(goal),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  icon: Icons.restaurant,
                  iconColor: AppColors.blue,
                  label: 'GEGESSEN',
                  value: _fmt(eaten),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  icon: Icons.local_fire_department_outlined,
                  iconColor: AppColors.teal,
                  label: 'VERBRANNT',
                  value: _fmt(burned),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _fmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final fromEnd = s.length - i;
      buf.write(s[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buf.write('.');
    }
    return buf.toString();
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.cardSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 14),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Text(
            'kcal',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Progress Ring (mit Gradient)
// ---------------------------------------------------------------------------

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
    const stroke = 12.0;
    final rect = Offset(stroke / 2, stroke / 2) &
        Size(size.width - stroke, size.height - stroke);
    final center = rect.center;
    final radius = rect.width / 2;

    // Track
    final track = Paint()
      ..color = AppColors.cardSoft
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    // Gradient-Arc
    const startAngle = -math.pi / 2;
    final sweep = 2 * math.pi * progress;

    final gradient = SweepGradient(
      startAngle: 0,
      endAngle: 2 * math.pi,
      transform: const GradientRotation(-math.pi / 2),
      colors: const [
        AppColors.violet,
        AppColors.blue,
        AppColors.teal,
        AppColors.teal,
      ],
      stops: const [0.0, 0.45, 0.85, 1.0],
    );

    final arc = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweep, false, arc);

    // Start-Dot (heller Punkt am Anfang des Bogens)
    final dotAngle = startAngle;
    final dotPos = Offset(
      center.dx + radius * math.cos(dotAngle),
      center.dy + radius * math.sin(dotAngle),
    );
    final dotPaint = Paint()..color = AppColors.blue.withOpacity(0.9);
    canvas.drawCircle(dotPos, stroke / 2 + 2, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}

// ---------------------------------------------------------------------------
// Makros
// ---------------------------------------------------------------------------

class _Macro {
  const _Macro(this.label, this.value, this.goal, this.color);
  final String label;
  final int value;
  final int goal;
  final Color color;

  double get progress => (value / goal).clamp(0.0, 1.0);
}

class _MacrosCard extends StatelessWidget {
  const _MacrosCard({
    required this.protein,
    required this.carbs,
    required this.fat,
  });
  final _Macro protein;
  final _Macro carbs;
  final _Macro fat;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'MAKROS HEUTE',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Row(
                children: const [
                  Text(
                    'Details ansehen',
                    style: TextStyle(
                      color: AppColors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right, color: AppColors.blue, size: 16),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _MacroTile(m: protein)),
              const SizedBox(width: 14),
              Expanded(child: _MacroTile(m: carbs)),
              const SizedBox(width: 14),
              Expanded(child: _MacroTile(m: fat)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroTile extends StatelessWidget {
  const _MacroTile({required this.m});
  final _Macro m;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          m.label,
          style: TextStyle(
            color: m.color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${m.value} g',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '/ ${m.goal} g',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 40,
              height: 40,
              child: _MiniRing(
                progress: m.progress,
                color: m.color,
                label: '${(m.progress * 100).round()}%',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: m.progress,
            minHeight: 4,
            backgroundColor: AppColors.cardSoft,
            valueColor: AlwaysStoppedAnimation(m.color),
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
          size: const Size.square(40),
          painter: _MiniRingPainter(progress: progress, color: color),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 9,
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
      ..color = AppColors.cardSoft
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

// ---------------------------------------------------------------------------
// Mahlzeiten
// ---------------------------------------------------------------------------

class _Meal {
  const _Meal(this.name, this.kcal, this.icon, this.color);
  final String name;
  final int kcal;
  final IconData icon;
  final Color color;
}

class _MealsCard extends StatelessWidget {
  const _MealsCard();

  static const _meals = <_Meal>[
    _Meal('Frühstück', 320, Icons.wb_sunny_outlined, AppColors.orange),
    _Meal('Mittagessen', 560, Icons.light_mode_outlined, AppColors.yellow),
    _Meal('Abendessen', 310, Icons.nights_stay_outlined, AppColors.sunset),
    _Meal('Snacks', 90, Icons.cookie_outlined, AppColors.lime),
  ];

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text(
                'MAHLZEITEN HEUTE',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              Spacer(),
              Text(
                'kcal',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final m in _meals) _MealRow(meal: m),
          const Divider(color: AppColors.stroke, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: const [
                Text(
                  'GESAMT',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                Spacer(),
                Text(
                  '1.280 kcal',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.chevron_right,
                    color: AppColors.textMuted, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MealRow extends StatelessWidget {
  const _MealRow({required this.meal});
  final _Meal meal;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(meal.icon, color: meal.color, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                meal.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              meal.kcal.toString(),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right,
                color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

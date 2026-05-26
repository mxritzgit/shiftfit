import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../common/basic_widgets.dart';

class ShiftTip {
  const ShiftTip({
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
  });

  final String title;
  final String body;
  final IconData icon;
  final Color color;
}

class TipOfDayCard extends StatelessWidget {
  const TipOfDayCard({super.key, required this.shift});

  final String shift;

  static const Map<String, List<ShiftTip>> _tipsByShift = {
    'Früh': [
      ShiftTip(
        title: 'Licht zuerst',
        body: '10 Min direktes Tageslicht direkt nach dem Aufstehen stabilisiert den Rhythmus.',
        icon: Icons.wb_sunny_outlined,
        color: orange,
      ),
      ShiftTip(
        title: 'Frühstück mit Protein',
        body: 'Eier, Quark oder Skyr halten die Energie länger als reines Brot oder Müsli.',
        icon: Icons.set_meal_outlined,
        color: lime,
      ),
      ShiftTip(
        title: 'Koffein dosiert',
        body: 'Nach dem Aufstehen 60-90 Min warten, dann erst Kaffee — das schiebt das Mittagstief nach hinten.',
        icon: Icons.coffee_outlined,
        color: orange,
      ),
    ],
    'Spät': [
      ShiftTip(
        title: 'Lange Mittagsschlaf vermeiden',
        body: 'Max. 20 Min Power Nap reicht. Längere Phasen kippen den Schlafanker.',
        icon: Icons.bedtime_outlined,
        color: wellnessTone,
      ),
      ShiftTip(
        title: 'Training vor der Schicht',
        body: 'Eine kurze Krafteinheit am späten Vormittag boostet Wachheit ohne den Abend zu zerstören.',
        icon: Icons.fitness_center,
        color: lime,
      ),
      ShiftTip(
        title: 'Letzte Mahlzeit leicht',
        body: 'Spät essen heißt früh aufhören — letzte größere Mahlzeit 3h vor Bett.',
        icon: Icons.dinner_dining_outlined,
        color: orange,
      ),
    ],
    'Nacht': [
      ShiftTip(
        title: 'Sonnenbrille morgens',
        body: 'Auf dem Heimweg nach der Nachtschicht Sonnenbrille schützt den Melatonin-Aufbau.',
        icon: Icons.dark_mode_outlined,
        color: wellnessTone,
      ),
      ShiftTip(
        title: 'Snack-Strategie',
        body: 'Nachts Joghurt, Banane, Nüsse oder eine warme Suppe — keine schweren Mahlzeiten.',
        icon: Icons.restaurant_outlined,
        color: orange,
      ),
      ShiftTip(
        title: 'Cooldown vor Schlaf',
        body: 'Nach der Schicht warme Dusche, kühles dunkles Zimmer, Box-Atmung 4-4-4-4.',
        icon: Icons.air,
        color: cyan,
      ),
    ],
    'Frei': [
      ShiftTip(
        title: 'Anker nicht auflösen',
        body: 'Auch frei: maximal 60 Min später ins Bett als an Arbeitstagen.',
        icon: Icons.bedtime_outlined,
        color: wellnessTone,
      ),
      ShiftTip(
        title: 'Meal Prep',
        body: 'Zwei Proteinbasen + zwei schnelle Carb-Optionen vorkochen spart den Rest der Woche.',
        icon: Icons.set_meal_outlined,
        color: lime,
      ),
      ShiftTip(
        title: 'Längeres Training',
        body: 'Heute darf es länger sein — Krafteinheit oder 30-45 Min Cardio.',
        icon: Icons.fitness_center,
        color: lime,
      ),
    ],
  };

  ShiftTip _pick() {
    final tips = _tipsByShift[shift] ?? _tipsByShift['Früh']!;
    final today = DateTime.now();
    final dayOfYear =
        today.difference(DateTime(today.year, 1, 1)).inDays;
    return tips[dayOfYear % tips.length];
  }

  @override
  Widget build(BuildContext context) {
    final tip = _pick();
    return AppCard(
      key: const ValueKey('tip-of-day-card'),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tip.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(rControl),
            ),
            child: Icon(tip.icon, color: tip.color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tip.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Text(
                      'Tipp',
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 10,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  tip.body,
                  style: const TextStyle(
                    color: textMuted,
                    fontSize: 12,
                    height: 1.4,
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

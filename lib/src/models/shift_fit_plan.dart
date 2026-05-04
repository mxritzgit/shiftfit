import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'plan_block.dart';

class ShiftFitPlan {
  const ShiftFitPlan({
    required this.recommendation,
    required this.focus,
    required this.tagline,
    required this.totalMinutes,
    required this.intensity,
    required this.recoveryScore,
    required this.accent,
    required this.blocks,
    required this.sleepHint,
    required this.fuelHint,
    required this.breathHint,
  });

  final String recommendation;
  final String focus;
  final String tagline;
  final int totalMinutes;
  final String intensity;
  final int recoveryScore;
  final Color accent;
  final List<PlanBlock> blocks;
  final String sleepHint;
  final String fuelHint;
  final String breathHint;

  static ShiftFitPlan from({
    required String shift,
    required String energy,
    required String stress,
  }) {
    if (energy == 'Müde' || stress == 'Hoch') {
      return const ShiftFitPlan(
        recommendation: 'Recovery Flow',
        focus: 'Runterfahren statt durchbeißen',
        tagline: 'Sanfte Bewegung, Atmung und frühes Licht für dein Nervensystem.',
        totalMinutes: 18,
        intensity: 'Leicht',
        recoveryScore: 62,
        accent: cyan,
        sleepHint: '90 Min vor Schlaf: Licht dimmen, Handy weg, Dusche warm.',
        fuelHint: 'Protein + warme Carbs. Koffein heute nur früh im Wachfenster.',
        breathHint: '4-7-8 Atmung: 4 Runden vor dem Hinlegen.',
        blocks: [
          PlanBlock('Mobility', '6 Min', Icons.self_improvement, 'Nacken, Hüfte, Rücken öffnen'),
          PlanBlock('Zone 1 Walk', '8 Min', Icons.directions_walk, 'Locker gehen, kein Pulsdruck'),
          PlanBlock('Breath Down', '4 Min', Icons.air, 'Lange Ausatmung, Schultern sinken lassen'),
        ],
      );
    }

    if (energy == 'Stark' && stress != 'Hoch') {
      return const ShiftFitPlan(
        recommendation: 'Kraft Session',
        focus: 'Kurz, schwer, sauber',
        tagline: 'Nutze das Energie-Fenster ohne dich für die nächste Schicht zu zerstören.',
        totalMinutes: 32,
        intensity: 'Stark',
        recoveryScore: 86,
        accent: lime,
        sleepHint: 'Nach Training 10 Min Cooldown, später keine hellen Screens.',
        fuelHint: 'Vorher Snack, danach Protein + Elektrolyte.',
        breathHint: '2 Min Nasenatmung zwischen Arbeitssätzen.',
        blocks: [
          PlanBlock('Primer', '5 Min', Icons.flash_on, 'Gelenke wach, Core aktivieren'),
          PlanBlock('Strength', '22 Min', Icons.fitness_center, '3 Runden Kniebeuge, Push, Pull'),
          PlanBlock('Cooldown', '5 Min', Icons.spa, 'Puls runter, Hüfte öffnen'),
        ],
      );
    }

    if (shift == 'Nacht') {
      return const ShiftFitPlan(
        recommendation: 'Mobility Reset',
        focus: 'Wach bleiben ohne Overload',
        tagline: 'Beweglichkeit, kurze Aktivierung und klare Schlaf-Brücke nach der Nacht.',
        totalMinutes: 22,
        intensity: 'Moderat',
        recoveryScore: 74,
        accent: pink,
        sleepHint: 'Nach Schicht Sonnenbrille, Zimmer kühl und dunkel.',
        fuelHint: 'Leicht essen: Joghurt, Banane, Nüsse oder Suppe.',
        breathHint: 'Box Breathing in der Pause: 4-4-4-4.',
        blocks: [
          PlanBlock('Reset', '7 Min', Icons.accessibility_new, 'Wirbelsäule und Hüfte mobilisieren'),
          PlanBlock('Carry', '10 Min', Icons.shopping_bag, 'Leichte Carries oder Treppe'),
          PlanBlock('Sleep Bridge', '5 Min', Icons.bedtime, 'Atmung + Licht aus Routine'),
        ],
      );
    }

    if (shift == 'Frei') {
      return const ShiftFitPlan(
        recommendation: 'Build & Recharge',
        focus: 'Etwas mehr Volumen, trotzdem smart',
        tagline: 'Freier Tag: Training, Meal Prep und ein stabiler Schlafanker.',
        totalMinutes: 40,
        intensity: 'Aufbau',
        recoveryScore: 81,
        accent: orange,
        sleepHint: 'Schlafanker halten: maximal 60 Min später ins Bett.',
        fuelHint: 'Meal Prep: 2 Proteinbasen + 2 schnelle Carb-Optionen.',
        breathHint: '5 Min Spaziergang nach der größten Mahlzeit.',
        blocks: [
          PlanBlock('Warm-up', '8 Min', Icons.local_fire_department, 'Dynamisch mobilisieren'),
          PlanBlock('Full Body', '24 Min', Icons.fitness_center, '4 Runden Ganzkörper'),
          PlanBlock('Recharge', '8 Min', Icons.spa, 'Stretch + Plan für morgen'),
        ],
      );
    }

    return const ShiftFitPlan(
      recommendation: '20 Min Training',
      focus: 'Effektiv zwischen Arbeit und Leben',
      tagline: 'Ein knackiger Reiz mit genug Reserve für deine nächste Schicht.',
      totalMinutes: 20,
      intensity: 'Moderat',
      recoveryScore: 78,
      accent: lime,
      sleepHint: 'Heute gleicher Schlafanker, auch wenn die Schicht früh startet.',
      fuelHint: 'Wasser + Salz, danach Protein. Koffein-Stopp 8 Std vor Schlaf.',
      breathHint: '3 Min langsame Nasenatmung nach dem Training.',
      blocks: [
        PlanBlock('Warm-up', '4 Min', Icons.local_fire_department, 'Gelenke wach, Puls leicht hoch'),
        PlanBlock('Circuit', '12 Min', Icons.repeat, 'Squat, Push, Hinge, Core'),
        PlanBlock('Downshift', '4 Min', Icons.air, 'Cooldown und Atmung'),
      ],
    );
  }
}

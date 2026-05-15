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
    final goal = shift;

    if (energy == 'Müde' || stress == 'Hoch' || goal == 'Recovery') {
      return const ShiftFitPlan(
        recommendation: 'Recovery & Mobility',
        focus: 'Deload statt durchziehen',
        tagline: 'Gelenke pflegen, Puls niedrig halten und morgen wieder stärker sein.',
        totalMinutes: 22,
        intensity: 'Leicht',
        recoveryScore: 68,
        accent: cyan,
        sleepHint: 'Heute 30 Min früher runterfahren: Licht dimmen, Atemroutine, kein Scrollen im Bett.',
        fuelHint: 'Protein halten: 1.6-2.2 g/kg, dazu leicht verdauliche Carbs und genug Salz.',
        breathHint: '4-7-8 Atmung: 4 Runden nach dem Mobility-Block.',
        blocks: [
          PlanBlock('Mobility Reset', '8 Min', Icons.self_improvement, 'Hüfte, T-Spine und Sprunggelenke öffnen'),
          PlanBlock('Zone 2 Walk', '10 Min', Icons.directions_walk, 'Locker gehen, Nasenatmung, kein Pulsdruck'),
          PlanBlock('Breath Reset', '4 Min', Icons.air, 'Lange Ausatmung, Schultern sinken lassen'),
        ],
      );
    }

    if (goal == 'Kraft' && energy == 'Stark') {
      return const ShiftFitPlan(
        recommendation: 'Strength Builder',
        focus: 'Schwer, sauber, progressiv',
        tagline: 'Grundübungen zuerst, dann kurze Assistance für echte Kraftsteigerung.',
        totalMinutes: 45,
        intensity: 'Stark',
        recoveryScore: 88,
        accent: lime,
        sleepHint: 'Nach schweren Sätzen: 10 Min Cooldown und heute konsequent Schlaf priorisieren.',
        fuelHint: 'Vorher Carbs + Elektrolyte, danach 30-45 g Protein für Muskelaufbau.',
        breathHint: 'Zwischen Arbeitssätzen 5 tiefe Nasenatemzüge, dann erst der nächste Satz.',
        blocks: [
          PlanBlock('Warm-up', '7 Min', Icons.local_fire_department, 'RAMP: Puls, Mobilität, Aktivierung'),
          PlanBlock('Heavy Lift', '20 Min', Icons.fitness_center, 'Kniebeuge oder Hinge: 5x3-5 sauber'),
          PlanBlock('Push/Pull', '12 Min', Icons.sync_alt, 'Superset: Drücken + Ziehen, 3 Runden'),
          PlanBlock('Core Brace', '6 Min', Icons.shield_outlined, 'Plank, Dead Bug, Carry-Fokus'),
        ],
      );
    }

    if (goal == 'Ausdauer') {
      return const ShiftFitPlan(
        recommendation: 'Cardio Engine',
        focus: 'Ausdauer ohne Overload',
        tagline: 'Zone 2 Basis plus kurze Technik-Spitzen für ein stärkeres Herz-Kreislauf-System.',
        totalMinutes: 34,
        intensity: 'Moderat',
        recoveryScore: 80,
        accent: orange,
        sleepHint: 'Nach Cardio 5 Min runtergehen, duschen, danach kein weiterer Stressreiz.',
        fuelHint: 'Bei Einheiten über 30 Min: Wasser + Salz, danach Carbs und Protein auffüllen.',
        breathHint: 'Nasenatmung als Tempo-Limiter: wenn sie kippt, Intensität senken.',
        blocks: [
          PlanBlock('Warm-up', '5 Min', Icons.directions_walk, 'Locker anlaufen, Gelenke vorbereiten'),
          PlanBlock('Zone 2', '22 Min', Icons.favorite_border, 'Sprechtempo halten, gleichmäßiger Puls'),
          PlanBlock('Strides', '4 Min', Icons.speed, '4 kurze Technik-Steigerungen, nicht sprinten'),
          PlanBlock('Cooldown', '3 Min', Icons.spa, 'Atmung beruhigen und Waden lockern'),
        ],
      );
    }

    if (goal == 'Kraft') {
      return const ShiftFitPlan(
        recommendation: 'Strength Primer',
        focus: 'Technik vor Maximalgewicht',
        tagline: 'Ein kontrollierter Kraftreiz mit genug Reserve für konstante Progression.',
        totalMinutes: 36,
        intensity: 'Moderat',
        recoveryScore: 82,
        accent: lime,
        sleepHint: 'Qualität schlägt Volumen: heute mit 2 Wiederholungen Reserve stoppen.',
        fuelHint: 'Proteinanker setzen und Trainingsgewichte im nächsten Log leicht steigern.',
        breathHint: 'Vor jedem Satz: einatmen, Rumpfspannung, kontrollierte Wiederholung.',
        blocks: [
          PlanBlock('Warm-up', '6 Min', Icons.local_fire_department, 'Gelenke warm, Bewegung vorbereiten'),
          PlanBlock('Main Lift', '16 Min', Icons.fitness_center, '4 Runden Squat, Hinge oder Press'),
          PlanBlock('Pull + Carry', '10 Min', Icons.shopping_bag, 'Rücken und Griffkraft stabilisieren'),
          PlanBlock('Cooldown', '4 Min', Icons.air, 'Puls senken, Hüfte und Brust öffnen'),
        ],
      );
    }

    return const ShiftFitPlan(
      recommendation: 'Hypertrophy Plan',
      focus: 'Ganzkörper-Reiz mit klarer Progression',
      tagline: 'Kraft, Muskelaufbau und Core in einer kompakten Session mit sauberer Technik.',
      totalMinutes: 38,
      intensity: 'Aufbau',
      recoveryScore: 84,
      accent: lime,
      sleepHint: 'Muskelaufbau passiert in der Erholung: 7-9 Stunden Schlaf als Ziel setzen.',
      fuelHint: 'Für Aufbau: 1.6-2.2 g Protein/kg und kleine, nachhaltige Kalorienreserve.',
      breathHint: 'Nach der Session 3 Min langsame Nasenatmung für schnelleres Runterfahren.',
      blocks: [
        PlanBlock('Warm-up', '6 Min', Icons.local_fire_department, 'RAMP: Mobilität, Aktivierung, leichter Puls'),
        PlanBlock('Compound Lifts', '16 Min', Icons.fitness_center, 'Squat, Push, Pull, Hinge als Qualitätszirkel'),
        PlanBlock('Accessory Superset', '10 Min', Icons.repeat, 'Schultern, Rücken und Glutes mit Kontrolle'),
        PlanBlock('Core Finisher', '6 Min', Icons.grid_view_rounded, 'Plank, Dead Bug und Carry-Spannung'),
      ],
    );
  }
}

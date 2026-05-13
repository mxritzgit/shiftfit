import 'package:flutter/material.dart';

class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.unlocked,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool unlocked;
}

class AchievementCatalog {
  const AchievementCatalog();

  List<Achievement> evaluate({
    required int workoutStreak,
    required int dailyWaterMl,
    required int waterGoalMl,
    required int sleepMinutes,
    required int sleepGoalMinutes,
    required int dailyKcal,
    required int kcalGoal,
    required int stepsToday,
    required int stepsGoal,
    required Color limeColor,
    required Color cyanColor,
    required Color orangeColor,
    required Color pinkColor,
  }) {
    return [
      Achievement(
        id: 'hydrated',
        title: 'Hydriert',
        description: 'Wasserziel erreicht',
        icon: Icons.water_drop_rounded,
        color: cyanColor,
        unlocked: dailyWaterMl >= waterGoalMl && waterGoalMl > 0,
      ),
      Achievement(
        id: 'rested',
        title: 'Ausgeruht',
        description: 'Schlafziel erreicht',
        icon: Icons.bedtime_rounded,
        color: pinkColor,
        unlocked: sleepMinutes >= sleepGoalMinutes && sleepGoalMinutes > 0,
      ),
      Achievement(
        id: 'streak3',
        title: 'Streak 3',
        description: '3 Tage in Folge',
        icon: Icons.local_fire_department_rounded,
        color: orangeColor,
        unlocked: workoutStreak >= 3,
      ),
      Achievement(
        id: 'streak7',
        title: 'Streak 7',
        description: 'Eine ganze Woche',
        icon: Icons.workspace_premium_rounded,
        color: limeColor,
        unlocked: workoutStreak >= 7,
      ),
      Achievement(
        id: 'mover',
        title: 'Mover',
        description: '8.000 Schritte heute',
        icon: Icons.directions_walk_rounded,
        color: limeColor,
        unlocked: stepsToday >= 8000,
      ),
      Achievement(
        id: 'kcal-on-target',
        title: 'Im Ziel',
        description: 'Kcal-Bereich getroffen',
        icon: Icons.flag_rounded,
        color: orangeColor,
        unlocked: kcalGoal > 0 &&
            dailyKcal >= (kcalGoal * 0.85).round() &&
            dailyKcal <= (kcalGoal * 1.1).round(),
      ),
    ];
  }
}

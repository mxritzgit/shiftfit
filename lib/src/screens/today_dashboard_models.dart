import 'package:flutter/foundation.dart';

import '../models/caffeine_entry.dart';
import '../models/daily_mood.dart';
import '../models/habit.dart';
import '../models/sleep_entry.dart';
import '../models/weight_log.dart';
import '../services/health_service.dart';

/// ARCH-3: gruppiert den ANGEZEIGTEN Tages-Zustand der [TodayDashboard] in EIN
/// immutables Value-Object. Vorher wanderten ~20 Einzelwerte als separate
/// Konstruktor-Parameter durch — Prop-Drilling, das jede Feld-Aenderung in zwei
/// Dateien zwang. Hier liegen ausschliesslich Daten (keine Callbacks); die
/// Aktionen leben in [TodayActions].
///
/// REIN strukturell: identische Werte, identisches Rendering. Die HomePage baut
/// genau ein [DailyMetrics] aus ihrem State und reicht es durch.
@immutable
class DailyMetrics {
  const DailyMetrics({
    required this.selectedShift,
    required this.selectedEnergy,
    required this.selectedStress,
    required this.dailyConsumedKcal,
    required this.kcalGoal,
    required this.dailyWaterMl,
    required this.waterGoalMl,
    required this.dailySteps,
    required this.stepsGoal,
    required this.lastSleep,
    required this.sleepGoalMinutes,
    required this.completedBlockIds,
    required this.workoutStreak,
    required this.healthAuthState,
    required this.healthLastFetch,
    required this.caffeineDay,
    required this.mood,
    required this.habits,
    required this.weightLog,
  });

  final String selectedShift;
  final String selectedEnergy;
  final String selectedStress;
  final int dailyConsumedKcal;
  final int kcalGoal;
  final int dailyWaterMl;
  final int waterGoalMl;
  final int dailySteps;
  final int stepsGoal;
  final SleepEntry? lastSleep;
  final int sleepGoalMinutes;
  final Set<String> completedBlockIds;
  final int workoutStreak;
  final HealthAuthState healthAuthState;
  final DateTime? healthLastFetch;
  final CaffeineDay caffeineDay;
  final DailyMood mood;
  final HabitState habits;
  final WeightLog weightLog;
}

/// ARCH-3: gruppiert die Callbacks der [TodayDashboard] in EIN Value-Object.
/// Reines Handler-Buendel — keine Daten. So bleibt der Konstruktor der
/// Dashboard-Widget schlank und die HomePage hat genau eine Stelle, an der sie
/// ihre Methoden-Referenzen verdrahtet.
@immutable
class TodayActions {
  const TodayActions({
    required this.onShiftSelected,
    required this.onEnergySelected,
    required this.onStressSelected,
    required this.onToggleBlock,
    required this.onConnectHealth,
    required this.onRefreshHealth,
    required this.onAddWater,
    required this.onSetSteps,
    required this.onLogSleep,
    required this.onMoodScore,
    required this.onEditMoodNote,
    required this.onToggleHabit,
    required this.onAddCaffeine,
    required this.onResetCaffeine,
    required this.onLogWeight,
    required this.onOpenTraining,
    required this.onOpenFood,
  });

  final ValueChanged<String> onShiftSelected;
  final ValueChanged<String> onEnergySelected;
  final ValueChanged<String> onStressSelected;
  final ValueChanged<String> onToggleBlock;
  final VoidCallback onConnectHealth;
  final VoidCallback onRefreshHealth;
  final ValueChanged<int> onAddWater;
  final ValueChanged<int> onSetSteps;
  final VoidCallback onLogSleep;
  final ValueChanged<int> onMoodScore;
  final VoidCallback onEditMoodNote;
  final ValueChanged<String> onToggleHabit;
  final ValueChanged<int> onAddCaffeine;
  final VoidCallback onResetCaffeine;
  final ValueChanged<double> onLogWeight;
  final VoidCallback onOpenTraining;
  final VoidCallback onOpenFood;
}

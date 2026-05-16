import '../models/user_profile.dart';

/// Schätzt aktive Kilokalorien aus Schritten.
///
/// Das ist bewusst kein fixer "kcal pro Schritt"-Wert mehr. Schritte werden
/// erst über eine höhenbasierte Schrittlänge in Distanz umgerechnet, dann über
/// den etablierten Netto-Energieaufwand fürs Gehen geschätzt:
///
///   Distanz km = steps × stepLengthMeters / 1000
///   active kcal ≈ 0.5 × bodyWeightKg × distanceKm
///
/// Die 0.5 kcal/kg/km stammen aus der horizontalen Netto-Komponente der
/// ACSM-Walking-Gleichung (0.1 ml O2/kg/m × 5 kcal/L O2). Netto ist hier
/// wichtig: Das Food-Ziel enthält bereits Grundumsatz/Alltag; "Verbrannt" soll
/// nur den zusätzlichen Bewegungsbonus addieren, nicht Ruheumsatz doppelt.
/// Die Schrittlänge nutzt gängige Pedometer-Heuristiken aus der Körpergröße
/// (männlich 41.5%, weiblich 41.3%, neutral 41.4%).
///
/// Liefert nie negative Werte und ist gegen Nonsense-Eingaben abgesichert.
double estimateStepLengthMeters({
  required int heightCm,
  BiologicalSex sex = BiologicalSex.neutral,
}) {
  if (heightCm <= 0) return 0;
  final ratio = switch (sex) {
    BiologicalSex.male => 0.415,
    BiologicalSex.female => 0.413,
    BiologicalSex.neutral => 0.414,
  };
  return ((heightCm * ratio) / 100).clamp(0.45, 1.05).toDouble();
}

double estimateWalkingDistanceKm({
  required int steps,
  required int heightCm,
  BiologicalSex sex = BiologicalSex.neutral,
}) {
  if (steps <= 0 || heightCm <= 0) return 0;
  return steps * estimateStepLengthMeters(heightCm: heightCm, sex: sex) / 1000;
}

int estimateKcalBurnedFromSteps({
  required int steps,
  required int weightKg,
  required int heightCm,
  BiologicalSex sex = BiologicalSex.neutral,
}) {
  if (steps <= 0 || weightKg <= 0 || heightCm <= 0) {
    return 0;
  }
  final distanceKm = estimateWalkingDistanceKm(
    steps: steps,
    heightCm: heightCm,
    sex: sex,
  );
  final activeKcal = weightKg * distanceKm * 0.5;
  return activeKcal.clamp(0, 99999).round();
}

class KcalTargets {
  const KcalTargets({
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.bmr,
    required this.activityFactor,
  });

  final int kcal;
  final int proteinG;
  final int carbsG;
  final int fatG;
  final int bmr;
  final double activityFactor;

  String get activityLabel {
    if (activityFactor < 1.3) return 'sitzend';
    if (activityFactor < 1.45) return 'leicht aktiv';
    if (activityFactor < 1.65) return 'moderat aktiv';
    if (activityFactor < 1.8) return 'sehr aktiv';
    return 'extrem aktiv';
  }
}

class KcalCalculator {
  const KcalCalculator();

  /// Activity factor used to scale BMR into TDEE based on the user's daily
  /// step target. Numbers follow the common Harris-Benedict band convention:
  ///   <5000   → 1.2   sedentary
  ///   <7500   → 1.375 lightly active
  ///   <10000  → 1.55  moderately active
  ///   <12500  → 1.725 very active
  ///   ≥12500  → 1.9   extra active
  double activityFactorFromSteps(int stepsGoal) {
    if (stepsGoal < 5000) return 1.2;
    if (stepsGoal < 7500) return 1.375;
    if (stepsGoal < 10000) return 1.55;
    if (stepsGoal < 12500) return 1.725;
    return 1.9;
  }

  /// Mifflin-St Jeor basal metabolic rate. For [BiologicalSex.neutral] we
  /// average the male and female offsets (+5 / −161 → −78).
  double basalMetabolicRate({
    required int weightKg,
    required int heightCm,
    required int ageYears,
    required BiologicalSex sex,
  }) {
    final base = 10 * weightKg + 6.25 * heightCm - 5 * ageYears;
    final offset = switch (sex) {
      BiologicalSex.male => 5,
      BiologicalSex.female => -161,
      BiologicalSex.neutral => -78,
    };
    return base + offset;
  }

  KcalTargets calculate(UserProfile profile) {
    final bmr = basalMetabolicRate(
      weightKg: profile.weightKg,
      heightCm: profile.heightCm,
      ageYears: profile.ageYears,
      sex: profile.sex,
    );
    final factor = activityFactorFromSteps(profile.dailyStepsGoal);
    final tdee = bmr * factor;
    // Round daily kcal to nearest 50 for nicer-looking numbers.
    final kcal = ((tdee / 50).round() * 50).clamp(1200, 5000);

    // Macro split: 1.6 g protein per kg, 25% kcal from fat, rest carbs.
    final proteinG = (profile.weightKg * 1.6).round();
    final fatG = ((kcal * 0.25) / 9).round();
    final remainingKcal = kcal - proteinG * 4 - fatG * 9;
    final carbsG = (remainingKcal / 4).clamp(0, 800).round();

    return KcalTargets(
      kcal: kcal,
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
      bmr: bmr.round(),
      activityFactor: factor,
    );
  }
}

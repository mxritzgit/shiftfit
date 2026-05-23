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
    required this.maintenanceKcal,
    required this.goal,
  });

  /// Tagesziel inkl. Ziel-Delta — ohne Schritt-Bonus (der kommt dynamisch
  /// in der CaloriesOverviewCard oben drauf).
  final int kcal;
  final int proteinG;
  final int carbsG;
  final int fatG;
  final int bmr;

  /// Erhaltungsbedarf: BMR × Basis-Lebensstil-Faktor, ohne Ziel-Delta.
  final int maintenanceKcal;
  final WeightGoal goal;
}

class KcalCalculator {
  const KcalCalculator();

  /// Basis-Lebensstil-Faktor über dem BMR. Deckt Ruheumsatz + Alltag
  /// (Schlafen, Verdauung, beiläufige Bewegung) ab — bewusst sitzend
  /// angesetzt, weil die *tatsächlich* gegangenen Schritte separat als
  /// "Verbrannt" angerechnet werden (CaloriesOverviewCard).
  ///
  /// Früher wurde stattdessen das Schritt-*Ziel* in den TDEE gerechnet
  /// (×1.55 etc.) UND die echten Schritt-kcal nochmal addiert → ~300 kcal
  /// Doppelzählung. Mit dem festen Basis-Faktor ist das behoben.
  static const double baseLifestyleFactor = 1.2;

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
    final maintenance = bmr * baseLifestyleFactor;
    final goalAdjusted = maintenance + profile.weightGoal.kcalDelta;
    // Round daily kcal to nearest 50 for nicer-looking numbers.
    final kcal = ((goalAdjusted / 50).round() * 50).clamp(1200, 5000);

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
      maintenanceKcal: maintenance.round(),
      goal: profile.weightGoal,
    );
  }
}

enum BiologicalSex { male, female, neutral }

extension BiologicalSexLabel on BiologicalSex {
  String get label => switch (this) {
        BiologicalSex.male => 'männlich',
        BiologicalSex.female => 'weiblich',
        BiologicalSex.neutral => 'neutral',
      };
}

/// Alltags-Aktivität ohne gezähltes Training. Multipliziert den Grundumsatz
/// (BMR) zum Erhaltungsbedarf (TDEE) — die etablierten PAL-Faktoren. Schritte
/// werden zusätzlich getrennt als „Verbrannt" angerechnet, deshalb ist hier
/// bewusst der Alltags-Anteil gemeint, nicht das geplante Workout.
enum ActivityLevel { sedentary, light, moderate, active, athlete }

extension ActivityLevelInfo on ActivityLevel {
  /// Physical Activity Level (PAL) — Multiplikator auf den BMR.
  double get palFactor => switch (this) {
        ActivityLevel.sedentary => 1.2,
        ActivityLevel.light => 1.375,
        ActivityLevel.moderate => 1.55,
        ActivityLevel.active => 1.725,
        ActivityLevel.athlete => 1.9,
      };

  String get label => switch (this) {
        ActivityLevel.sedentary => 'Kaum aktiv',
        ActivityLevel.light => 'Leicht aktiv',
        ActivityLevel.moderate => 'Mäßig aktiv',
        ActivityLevel.active => 'Sehr aktiv',
        ActivityLevel.athlete => 'Extrem aktiv',
      };

  String get description => switch (this) {
        ActivityLevel.sedentary => 'Bürojob, wenig Bewegung',
        ActivityLevel.light => 'Leichte Bewegung, 1–2× Sport/Woche',
        ActivityLevel.moderate => 'Aktiver Alltag, 3–5× Sport/Woche',
        ActivityLevel.active => 'Täglich aktiv, 6–7× Sport/Woche',
        ActivityLevel.athlete => 'Körperliche Arbeit + tägl. Training',
      };
}

/// Gewichtsziel des Users. Bestimmt den kcal-Auf-/Abschlag auf den
/// Erhaltungsbedarf (BMR × Aktivitäts-PAL). Schritte werden davon getrennt
/// als "Verbrannt" angerechnet — siehe [KcalCalculator].
enum WeightGoal { loseFast, loseSteady, maintain, gainSteady, gainFast }

extension WeightGoalInfo on WeightGoal {
  String get label => switch (this) {
        WeightGoal.loseFast => 'Abnehmen (schnell)',
        WeightGoal.loseSteady => 'Abnehmen',
        WeightGoal.maintain => 'Gewicht halten',
        WeightGoal.gainSteady => 'Zunehmen',
        WeightGoal.gainFast => 'Zunehmen (schnell)',
      };

  /// kcal-Delta auf den Erhaltungsbedarf. Annahme ~7700 kcal pro kg.
  int get kcalDelta => switch (this) {
        WeightGoal.loseFast => -500,
        WeightGoal.loseSteady => -300,
        WeightGoal.maintain => 0,
        WeightGoal.gainSteady => 300,
        WeightGoal.gainFast => 500,
      };

  /// Erwartetes Tempo fürs UI-Hint.
  String get paceLabel => switch (this) {
        WeightGoal.loseFast => '~0,5 kg/Woche',
        WeightGoal.loseSteady => '~0,3 kg/Woche',
        WeightGoal.maintain => 'Gewicht stabil',
        WeightGoal.gainSteady => '~0,3 kg/Woche',
        WeightGoal.gainFast => '~0,5 kg/Woche',
      };

  /// Erwartete kg-Veränderung pro Woche (≈ 7700 kcal pro kg Körpermasse).
  /// Vorzeichenlos — die Richtung steckt in [isLoss]/[isGain].
  double get weeklyRateKg => kcalDelta.abs() * 7 / 7700;

  bool get isLoss => kcalDelta < 0;
  bool get isGain => kcalDelta > 0;

  /// Vorzeichenbehaftetes Delta-Label, z.B. "−500 kcal" / "±0".
  String get deltaLabel {
    if (kcalDelta == 0) return '±0';
    final sign = kcalDelta > 0 ? '+' : '−';
    return '$sign${kcalDelta.abs()} kcal';
  }
}

class UserProfile {
  const UserProfile({
    this.weightKg = 78,
    this.heightCm = 178,
    this.ageYears = 30,
    this.sex = BiologicalSex.neutral,
    this.activityLevel = ActivityLevel.sedentary,
    this.targetWeightKg = 78,
    this.dailyStepsGoal = 8000,
    this.dailyKcalGoal = 2200,
    this.dailyWaterGoalMl = 2500,
    this.dailySleepGoalMinutes = 7 * 60 + 30,
    this.proteinGoalG = 130,
    this.carbsGoalG = 240,
    this.fatGoalG = 70,
    this.weightGoal = WeightGoal.maintain,
    this.onboardingCompleted = false,
  });

  final int weightKg;
  final int heightCm;
  final int ageYears;
  final BiologicalSex sex;

  /// Alltags-Aktivität für den Erhaltungsbedarf (PAL). Default sedentär (1.2),
  /// damit Bestands-Berechnungen unverändert bleiben.
  final ActivityLevel activityLevel;

  /// Wunschgewicht. Treibt nur die Zeit-Prognose (Wochen bis Ziel), nicht das
  /// Tagesziel selbst — das hängt am gewählten Tempo ([weightGoal]).
  final int targetWeightKg;

  final int dailyStepsGoal;
  final int dailyKcalGoal;
  final int dailyWaterGoalMl;
  final int dailySleepGoalMinutes;
  final int proteinGoalG;
  final int carbsGoalG;
  final int fatGoalG;
  final WeightGoal weightGoal;

  /// True sobald der User das verpflichtende Onboarding durchlaufen hat.
  /// Steuert das Gate in [ShiftFitHomePage] — gespiegelt nach
  /// public.profiles.onboarding_completed.
  final bool onboardingCompleted;

  UserProfile copyWith({
    int? weightKg,
    int? heightCm,
    int? ageYears,
    BiologicalSex? sex,
    ActivityLevel? activityLevel,
    int? targetWeightKg,
    int? dailyStepsGoal,
    int? dailyKcalGoal,
    int? dailyWaterGoalMl,
    int? dailySleepGoalMinutes,
    int? proteinGoalG,
    int? carbsGoalG,
    int? fatGoalG,
    WeightGoal? weightGoal,
    bool? onboardingCompleted,
  }) {
    return UserProfile(
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      ageYears: ageYears ?? this.ageYears,
      sex: sex ?? this.sex,
      activityLevel: activityLevel ?? this.activityLevel,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      dailyStepsGoal: dailyStepsGoal ?? this.dailyStepsGoal,
      dailyKcalGoal: dailyKcalGoal ?? this.dailyKcalGoal,
      dailyWaterGoalMl: dailyWaterGoalMl ?? this.dailyWaterGoalMl,
      dailySleepGoalMinutes:
          dailySleepGoalMinutes ?? this.dailySleepGoalMinutes,
      proteinGoalG: proteinGoalG ?? this.proteinGoalG,
      carbsGoalG: carbsGoalG ?? this.carbsGoalG,
      fatGoalG: fatGoalG ?? this.fatGoalG,
      weightGoal: weightGoal ?? this.weightGoal,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }
}

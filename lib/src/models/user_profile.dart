enum BiologicalSex { male, female, neutral }

extension BiologicalSexLabel on BiologicalSex {
  String get label => switch (this) {
        BiologicalSex.male => 'männlich',
        BiologicalSex.female => 'weiblich',
        BiologicalSex.neutral => 'neutral',
      };
}

/// Gewichtsziel des Users. Bestimmt den kcal-Auf-/Abschlag auf den
/// Erhaltungsbedarf (BMR × Basis-Lebensstil-Faktor). Schritte werden
/// davon getrennt als "Verbrannt" angerechnet — siehe [KcalCalculator].
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
    this.dailyStepsGoal = 8000,
    this.dailyKcalGoal = 2200,
    this.dailyWaterGoalMl = 2500,
    this.dailySleepGoalMinutes = 7 * 60 + 30,
    this.proteinGoalG = 130,
    this.carbsGoalG = 240,
    this.fatGoalG = 70,
    this.weightGoal = WeightGoal.maintain,
  });

  final int weightKg;
  final int heightCm;
  final int ageYears;
  final BiologicalSex sex;
  final int dailyStepsGoal;
  final int dailyKcalGoal;
  final int dailyWaterGoalMl;
  final int dailySleepGoalMinutes;
  final int proteinGoalG;
  final int carbsGoalG;
  final int fatGoalG;
  final WeightGoal weightGoal;

  UserProfile copyWith({
    int? weightKg,
    int? heightCm,
    int? ageYears,
    BiologicalSex? sex,
    int? dailyStepsGoal,
    int? dailyKcalGoal,
    int? dailyWaterGoalMl,
    int? dailySleepGoalMinutes,
    int? proteinGoalG,
    int? carbsGoalG,
    int? fatGoalG,
    WeightGoal? weightGoal,
  }) {
    return UserProfile(
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      ageYears: ageYears ?? this.ageYears,
      sex: sex ?? this.sex,
      dailyStepsGoal: dailyStepsGoal ?? this.dailyStepsGoal,
      dailyKcalGoal: dailyKcalGoal ?? this.dailyKcalGoal,
      dailyWaterGoalMl: dailyWaterGoalMl ?? this.dailyWaterGoalMl,
      dailySleepGoalMinutes:
          dailySleepGoalMinutes ?? this.dailySleepGoalMinutes,
      proteinGoalG: proteinGoalG ?? this.proteinGoalG,
      carbsGoalG: carbsGoalG ?? this.carbsGoalG,
      fatGoalG: fatGoalG ?? this.fatGoalG,
      weightGoal: weightGoal ?? this.weightGoal,
    );
  }
}

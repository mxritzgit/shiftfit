import 'package:flutter_test/flutter_test.dart';
import 'package:shiftfit/src/models/user_profile.dart';
import 'package:shiftfit/src/services/kcal_calculator.dart';

void main() {
  group('estimateKcalBurnedFromSteps', () {
    test('uses body weight and height-derived walking distance', () {
      final averageMale = estimateKcalBurnedFromSteps(
        steps: 10000,
        weightKg: 78,
        heightCm: 178,
        sex: BiologicalSex.male,
      );
      final heavierMale = estimateKcalBurnedFromSteps(
        steps: 10000,
        weightKg: 200,
        heightCm: 178,
        sex: BiologicalSex.male,
      );
      final lighterMale = estimateKcalBurnedFromSteps(
        steps: 10000,
        weightKg: 67,
        heightCm: 178,
        sex: BiologicalSex.male,
      );

      expect(averageMale, 288);
      expect(heavierMale, 739);
      expect(lighterMale, 247);
      expect(heavierMale, greaterThan(lighterMale));
    });

    test('uses profile height so taller users burn more for the same step count', () {
      final shorter = estimateKcalBurnedFromSteps(
        steps: 10000,
        weightKg: 78,
        heightCm: 165,
        sex: BiologicalSex.neutral,
      );
      final taller = estimateKcalBurnedFromSteps(
        steps: 10000,
        weightKg: 78,
        heightCm: 195,
        sex: BiologicalSex.neutral,
      );

      expect(shorter, 266);
      expect(taller, 315);
      expect(taller, greaterThan(shorter));
    });

    test('returns zero for invalid step or body inputs', () {
      expect(
        estimateKcalBurnedFromSteps(
          steps: 0,
          weightKg: 78,
          heightCm: 178,
          sex: BiologicalSex.neutral,
        ),
        0,
      );
      expect(
        estimateKcalBurnedFromSteps(
          steps: 10000,
          weightKg: 0,
          heightCm: 178,
          sex: BiologicalSex.neutral,
        ),
        0,
      );
      expect(
        estimateKcalBurnedFromSteps(
          steps: 10000,
          weightKg: 78,
          heightCm: 0,
          sex: BiologicalSex.neutral,
        ),
        0,
      );
    });
  });

  group('KcalCalculator.calculate', () {
    const calc = KcalCalculator();
    const base = UserProfile(); // 78kg, 178cm, 30J, neutral

    test('maintenance uses base lifestyle factor, not the step goal', () {
      // Der Bug war: Tagesbedarf wurde aus dem Schritt-ZIEL hochgerechnet
      // und die echten Schritte nochmal addiert. Jetzt darf das Schrittziel
      // den Bedarf NICHT mehr beeinflussen.
      final low = calc.calculate(base.copyWith(dailyStepsGoal: 3000));
      final high = calc.calculate(base.copyWith(dailyStepsGoal: 15000));
      expect(low.kcal, high.kcal);
      expect(low.maintenanceKcal, high.maintenanceKcal);
    });

    test('maintain goal targets the maintenance need (~BMR x 1.2)', () {
      final t = calc.calculate(base); // WeightGoal.maintain
      expect(t.goal, WeightGoal.maintain);
      expect(t.maintenanceKcal, 1997); // 1664.5 BMR x 1.2
      expect(t.kcal, 2000); // auf 50 gerundet
    });

    test('weight goal applies its kcal delta on top of maintenance', () {
      final maintain = calc.calculate(base.copyWith(weightGoal: WeightGoal.maintain));
      final loseFast = calc.calculate(base.copyWith(weightGoal: WeightGoal.loseFast));
      final gainFast = calc.calculate(base.copyWith(weightGoal: WeightGoal.gainFast));

      expect(loseFast.kcal, maintain.kcal - 500);
      expect(gainFast.kcal, maintain.kcal + 500);
      // Erhaltungsbedarf bleibt unabhängig vom Ziel gleich.
      expect(loseFast.maintenanceKcal, maintain.maintenanceKcal);
      expect(gainFast.maintenanceKcal, maintain.maintenanceKcal);
    });

    test('clamps daily kcal into a sane range', () {
      final tiny = calc.calculate(const UserProfile(
        weightKg: 35,
        heightCm: 140,
        ageYears: 80,
        weightGoal: WeightGoal.loseFast,
      ));
      expect(tiny.kcal, greaterThanOrEqualTo(1200));
    });
  });
}

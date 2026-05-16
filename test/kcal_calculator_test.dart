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
}

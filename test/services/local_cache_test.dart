import 'package:flutter_test/flutter_test.dart';

import 'package:shiftfit/src/models/lifetime_stats.dart';
import 'package:shiftfit/src/models/user_profile.dart';
import 'package:shiftfit/src/services/daily_log_sync.dart';
import 'package:shiftfit/src/services/local_cache.dart';

// DATA-3: LocalCache ist der durable Write-Through-Cache (JSON) fuer Profil,
// heutiges daily_logs und lifetime_stats. Diese Tests treiben ihn ueber den
// InMemoryKeyValueStore (kein SharedPreferences-Channel noetig) und sichern:
//   1. Profil/Tageslog/Stats roundtrippen verlustfrei.
//   2. readDailyLog gibt bei Tageswechsel null zurueck (kein Gestern-Leak).
//   3. Korrupte/teilweise Eintraege liefern null statt zu crashen.
//   4. Ein leerer Cache liefert ueberall null (Kaltstart ohne Vorstand).
//   5. clear() entfernt alle drei Eintraege.
//   6. Der Cache ist pro userId getrennt (kein Cross-User-Leak).

LocalCache _cache(InMemoryKeyValueStore store, [String userId = 'user-1']) =>
    LocalCache(store, userId);

void main() {
  group('LocalCache Profil', () {
    test('roundtrippt ein vollstaendiges Profil verlustfrei', () async {
      final store = InMemoryKeyValueStore();
      final cache = _cache(store);
      const profile = UserProfile(
        weightKg: 82,
        heightCm: 181,
        ageYears: 34,
        sex: BiologicalSex.male,
        activityLevel: ActivityLevel.active,
        targetWeightKg: 77,
        dailyStepsGoal: 9000,
        dailyKcalGoal: 2450,
        dailyWaterGoalMl: 3000,
        dailySleepGoalMinutes: 8 * 60,
        proteinGoalG: 160,
        carbsGoalG: 250,
        fatGoalG: 80,
        weightGoal: WeightGoal.lose05kg,
        onboardingCompleted: true,
      );

      await cache.writeProfile(profile);
      final back = await cache.readProfile();

      expect(back, isNotNull);
      expect(back!.weightKg, 82);
      expect(back.heightCm, 181);
      expect(back.ageYears, 34);
      expect(back.sex, BiologicalSex.male);
      expect(back.activityLevel, ActivityLevel.active);
      expect(back.targetWeightKg, 77);
      expect(back.dailyStepsGoal, 9000);
      expect(back.dailyKcalGoal, 2450);
      expect(back.dailyWaterGoalMl, 3000);
      expect(back.dailySleepGoalMinutes, 8 * 60);
      expect(back.proteinGoalG, 160);
      expect(back.carbsGoalG, 250);
      expect(back.fatGoalG, 80);
      expect(back.weightGoal, WeightGoal.lose05kg);
      expect(back.onboardingCompleted, isTrue);
    });

    test('leerer Cache -> null (kein Default-Profil aus dem Nichts)', () async {
      final cache = _cache(InMemoryKeyValueStore());
      expect(await cache.readProfile(), isNull);
    });

    test('korrupter Eintrag -> null statt Crash', () async {
      final store = InMemoryKeyValueStore({
        'fitpilot.v1.profile.user-1': '{ das ist kein json',
      });
      expect(await _cache(store).readProfile(), isNull);
    });

    test('unbekannte enum-Strings fallen auf Defaults (kein Crash)', () async {
      final store = InMemoryKeyValueStore({
        'fitpilot.v1.profile.user-1':
            '{"sex":"divers","activity_level":"couch","weight_goal":"hyperbulk"}',
      });
      final back = await _cache(store).readProfile();
      expect(back, isNotNull);
      expect(back!.sex, BiologicalSex.neutral);
      expect(back.activityLevel, ActivityLevel.sedentary);
      expect(back.weightGoal, WeightGoal.maintain);
      // Fehlende Zahlen-Spalten fallen auf die Ctor-Defaults.
      expect(back.weightKg, 78);
      expect(back.heightCm, 178);
    });
  });

  group('LocalCache daily_logs', () {
    DailyLog log(DateTime date) => DailyLog(
          date: date,
          waterMl: 1500,
          steps: 8200,
          moodScore: 4,
          moodNote: 'solide',
          completedBlockIds: const <String>{'1:Warm-up', '2:Kraft'},
          completedHabitIds: const <String>{'wasser'},
          workoutCompleted: true,
        );

    test('roundtrippt den heutigen Tagesstand verlustfrei', () async {
      final store = InMemoryKeyValueStore();
      final cache = _cache(store);
      final today = DateTime.now();

      await cache.writeDailyLog(log(today));
      final back = await cache.readDailyLog(today);

      expect(back, isNotNull);
      expect(back!.waterMl, 1500);
      expect(back.steps, 8200);
      expect(back.moodScore, 4);
      expect(back.moodNote, 'solide');
      expect(back.completedBlockIds, {'1:Warm-up', '2:Kraft'});
      expect(back.completedHabitIds, {'wasser'});
      expect(back.workoutCompleted, isTrue);
    });

    test('Tageswechsel: gestriger Stand wird NICHT als heute geliefert',
        () async {
      final store = InMemoryKeyValueStore();
      final cache = _cache(store);
      final yesterday = DateTime.now().subtract(const Duration(days: 1));

      await cache.writeDailyLog(log(yesterday));
      // Lesen fuer HEUTE -> null (frischer Tag startet bei 0, kein Gestern-Leak).
      expect(await cache.readDailyLog(DateTime.now()), isNull);
      // Lesen fuer GESTERN -> Treffer.
      expect(await cache.readDailyLog(yesterday), isNotNull);
    });
  });

  group('LocalCache lifetime_stats', () {
    test('roundtrippt inkl. Streak-Felder', () async {
      final store = InMemoryKeyValueStore();
      final cache = _cache(store);
      final stats = LifetimeStats(
        workoutsCompleted: 12,
        mealsLogged: 88,
        waterTotalMl: 42000,
        stepsRecorded: 310000,
        weightLogs: 9,
        currentStreak: 4,
        longestStreak: 11,
        lastWorkoutDate: DateTime(2026, 6, 3),
      );

      await cache.writeLifetimeStats(stats);
      final back = await cache.readLifetimeStats();

      expect(back, isNotNull);
      expect(back!.workoutsCompleted, 12);
      expect(back.mealsLogged, 88);
      expect(back.waterTotalMl, 42000);
      expect(back.stepsRecorded, 310000);
      expect(back.weightLogs, 9);
      expect(back.currentStreak, 4);
      expect(back.longestStreak, 11);
      expect(back.lastWorkoutDate, DateTime(2026, 6, 3));
    });

    test('leerer Cache -> null', () async {
      expect(await _cache(InMemoryKeyValueStore()).readLifetimeStats(), isNull);
    });
  });

  group('LocalCache Housekeeping', () {
    test('clear() entfernt Profil + Tageslog + Stats', () async {
      final store = InMemoryKeyValueStore();
      final cache = _cache(store);
      await cache.writeProfile(const UserProfile(weightKg: 90));
      await cache.writeDailyLog(DailyLog(date: DateTime.now(), waterMl: 500));
      await cache.writeLifetimeStats(LifetimeStats(mealsLogged: 3));

      await cache.clear();

      expect(await cache.readProfile(), isNull);
      expect(await cache.readDailyLog(DateTime.now()), isNull);
      expect(await cache.readLifetimeStats(), isNull);
    });

    test('Cache ist pro userId getrennt (kein Cross-User-Leak)', () async {
      final store = InMemoryKeyValueStore();
      final a = _cache(store, 'user-a');
      final b = _cache(store, 'user-b');

      await a.writeProfile(const UserProfile(weightKg: 95));
      // user-b hat nichts geschrieben -> sieht user-a NICHT.
      expect(await b.readProfile(), isNull);
      expect((await a.readProfile())!.weightKg, 95);
    });
  });
}

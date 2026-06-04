import 'package:flutter_test/flutter_test.dart';

import 'package:shiftfit/src/models/caffeine_entry.dart';
import 'package:shiftfit/src/models/lifetime_stats.dart';
import 'package:shiftfit/src/services/notification_content_engine.dart';

// Reine, deterministische Unit-Tests fuer NotificationContentEngine (PROD-1).
// Die Engine ist flutter-/IO-frei und nimmt `now` als Parameter — wir koennen
// daher alle Zeitfenster hart festnageln, ohne den Clock zu mocken. Geprueft
// werden: Hydration-nach-X, Koffein-Cutoff (schichtabhaengig), Schlaf-Runway,
// der NEUE Abend-Streak-at-risk-Nudge (feuert nur bei aktiver Streak + kein
// Workout heute) sowie die Invarianten "keine Duplikate / alles in der Zukunft".

const engine = NotificationContentEngine();

CaffeineDay _withCoffee(DateTime now) => CaffeineDay(
      entries: [CaffeineEntry(timestamp: now, mg: 80)],
    );

NotificationSpec? _byCategory(
  List<NotificationSpec> specs,
  NotificationCategory category,
) {
  for (final s in specs) {
    if (s.category == category) return s;
  }
  return null;
}

LifetimeStats _stats({
  int currentStreak = 0,
  DateTime? lastWorkoutDate,
}) {
  return LifetimeStats(
    currentStreak: currentStreak,
    lastWorkoutDate: lastWorkoutDate,
    sessionStart: DateTime(2026, 1, 1),
  );
}

List<NotificationSpec> _run({
  required DateTime now,
  String shift = 'Spät',
  int dailyWaterMl = 2000,
  int waterGoalMl = 2500,
  CaffeineDay? caffeineDay,
  int? lastBedtimeMinutes,
  int sleepGoalMinutes = 8 * 60,
  LifetimeStats? stats,
}) {
  return engine.buildSchedule(
    now: now,
    shift: shift,
    dailyWaterMl: dailyWaterMl,
    waterGoalMl: waterGoalMl,
    caffeineDay: caffeineDay ?? const CaffeineDay(),
    lastBedtimeMinutes: lastBedtimeMinutes,
    sleepGoalMinutes: sleepGoalMinutes,
    stats: stats ?? _stats(),
  );
}

void main() {
  group('Hydration-Nudge', () {
    test('plant 11:00, wenn morgens unter 40% des Ziels', () {
      final now = DateTime(2026, 6, 4, 8, 0);
      final specs = _run(
        now: now,
        dailyWaterMl: 200,
        waterGoalMl: 2500, // 40% = 1000, 200 < 1000 -> faellig
      );
      final h = _byCategory(specs, NotificationCategory.hydration);
      expect(h, isNotNull);
      expect(h!.scheduledFor, DateTime(2026, 6, 4, 11, 0));
      expect(h.body, 'Noch 2300 ml bis zum Tagesziel.');
      expect(h.id, NotificationContentEngine.idHydration);
    });

    test('feuert NICHT, wenn Ziel zu >= 40% erreicht', () {
      final specs = _run(
        now: DateTime(2026, 6, 4, 8, 0),
        dailyWaterMl: 1200,
        waterGoalMl: 2500, // 40% = 1000, 1200 >= 1000 -> kein Nudge
      );
      expect(_byCategory(specs, NotificationCategory.hydration), isNull);
    });

    test('plant naechste volle Stunde, wenn schon nach 11 und noch trocken',
        () {
      final now = DateTime(2026, 6, 4, 14, 23);
      final specs = _run(now: now, dailyWaterMl: 100, waterGoalMl: 2500);
      final h = _byCategory(specs, NotificationCategory.hydration);
      expect(h, isNotNull);
      expect(h!.scheduledFor, DateTime(2026, 6, 4, 15, 0));
    });

    test('feuert NICHT mehr spaet am Abend (>= 21 Uhr)', () {
      final specs = _run(
        now: DateTime(2026, 6, 4, 21, 30),
        dailyWaterMl: 100,
        waterGoalMl: 2500,
      );
      expect(_byCategory(specs, NotificationCategory.hydration), isNull);
    });

    test('feuert NICHT bei Ziel 0 (Division/Unsinn vermieden)', () {
      final specs = _run(
        now: DateTime(2026, 6, 4, 8, 0),
        dailyWaterMl: 0,
        waterGoalMl: 0,
      );
      expect(_byCategory(specs, NotificationCategory.hydration), isNull);
    });
  });

  group('Koffein-Cutoff (schichtabhaengig)', () {
    test('Spaet-Schicht: plant 60 Min vor 18:00 -> 17:00', () {
      final now = DateTime(2026, 6, 4, 9, 0);
      final specs = _run(
        now: now,
        shift: 'Spät',
        caffeineDay: _withCoffee(DateTime(2026, 6, 4, 8, 0)),
      );
      final c = _byCategory(specs, NotificationCategory.caffeine);
      expect(c, isNotNull);
      expect(c!.scheduledFor, DateTime(2026, 6, 4, 17, 0));
      expect(c.body, contains('18:00'));
    });

    test('feuert NICHT ohne Koffein-Eintrag heute', () {
      final specs = _run(
        now: DateTime(2026, 6, 4, 9, 0),
        shift: 'Spät',
        caffeineDay: const CaffeineDay(),
      );
      expect(_byCategory(specs, NotificationCategory.caffeine), isNull);
    });

    test('feuert NICHT, wenn das Cutoff-Fenster heute schon vorbei ist', () {
      // Spaet-Cutoff 18:00 -> Warnzeit 17:00; jetzt 17:30 -> in der
      // Vergangenheit, kein Spec.
      final specs = _run(
        now: DateTime(2026, 6, 4, 17, 30),
        shift: 'Spät',
        caffeineDay: _withCoffee(DateTime(2026, 6, 4, 8, 0)),
      );
      expect(_byCategory(specs, NotificationCategory.caffeine), isNull);
    });

    test('Frueh-Schicht hat frueheren Cutoff (13:00 -> Warnung 12:00)', () {
      final specs = _run(
        now: DateTime(2026, 6, 4, 6, 0),
        shift: 'Früh',
        caffeineDay: _withCoffee(DateTime(2026, 6, 4, 5, 30)),
      );
      final c = _byCategory(specs, NotificationCategory.caffeine);
      expect(c, isNotNull);
      expect(c!.scheduledFor, DateTime(2026, 6, 4, 12, 0));
    });
  });

  group('Schlaf-Runway', () {
    test('plant 90 Min vor Bettzeit (Bettzeit 23:00 -> 21:30)', () {
      final now = DateTime(2026, 6, 4, 19, 0);
      final specs = _run(
        now: now,
        lastBedtimeMinutes: 23 * 60, // 23:00
      );
      final s = _byCategory(specs, NotificationCategory.sleep);
      expect(s, isNotNull);
      expect(s!.scheduledFor, DateTime(2026, 6, 4, 21, 30));
      expect(s.body, contains('90 Min'));
    });

    test('feuert NICHT ohne geloggte Bettzeit', () {
      final specs = _run(now: DateTime(2026, 6, 4, 19, 0));
      expect(_byCategory(specs, NotificationCategory.sleep), isNull);
    });

    test('feuert NICHT, wenn das Prep-Fenster schon angebrochen ist', () {
      // Bettzeit 23:00 -> Prep 21:30; jetzt 22:00 -> Vergangenheit.
      final specs = _run(
        now: DateTime(2026, 6, 4, 22, 0),
        lastBedtimeMinutes: 23 * 60,
      );
      expect(_byCategory(specs, NotificationCategory.sleep), isNull);
    });
  });

  group('Streak-at-risk (NEU, abendlich)', () {
    test('feuert bei aktiver Streak + KEIN Workout heute -> 19:00', () {
      final now = DateTime(2026, 6, 4, 14, 0);
      final specs = _run(
        now: now,
        stats: _stats(
          currentStreak: 5,
          lastWorkoutDate: DateTime(2026, 6, 3), // gestern
        ),
      );
      final k = _byCategory(specs, NotificationCategory.streak);
      expect(k, isNotNull);
      expect(k!.scheduledFor, DateTime(2026, 6, 4, 19, 0));
      expect(k.body, contains('5-Tage-Streak'));
      expect(k.id, NotificationContentEngine.idStreak);
    });

    test('feuert NICHT, wenn keine Streak aktiv ist', () {
      final specs = _run(
        now: DateTime(2026, 6, 4, 14, 0),
        stats: _stats(currentStreak: 0, lastWorkoutDate: DateTime(2026, 6, 3)),
      );
      expect(_byCategory(specs, NotificationCategory.streak), isNull);
    });

    test('feuert NICHT, wenn heute schon trainiert wurde', () {
      final now = DateTime(2026, 6, 4, 14, 0);
      final specs = _run(
        now: now,
        stats: _stats(
          currentStreak: 5,
          lastWorkoutDate: DateTime(2026, 6, 4), // heute
        ),
      );
      expect(_byCategory(specs, NotificationCategory.streak), isNull);
    });

    test('feuert NICHT mehr kurz vor Mitternacht (>= 23 Uhr)', () {
      final specs = _run(
        now: DateTime(2026, 6, 4, 23, 15),
        stats: _stats(
          currentStreak: 3,
          lastWorkoutDate: DateTime(2026, 6, 3),
        ),
      );
      expect(_byCategory(specs, NotificationCategory.streak), isNull);
    });

    test('plant sofort (+1 Min), wenn abends nach 19 Uhr noch offen', () {
      final now = DateTime(2026, 6, 4, 20, 30);
      final specs = _run(
        now: now,
        stats: _stats(
          currentStreak: 2,
          lastWorkoutDate: DateTime(2026, 6, 3),
        ),
      );
      final k = _byCategory(specs, NotificationCategory.streak);
      expect(k, isNotNull);
      expect(k!.scheduledFor, DateTime(2026, 6, 4, 20, 31));
    });
  });

  group('Morgen-Tageslicht (schichtspezifisch)', () {
    test('Frueh-Schicht vor 9 Uhr -> Anker 07:00', () {
      final specs = _run(
        now: DateTime(2026, 6, 4, 5, 30),
        shift: 'Früh',
      );
      final m = _byCategory(specs, NotificationCategory.morningLight);
      expect(m, isNotNull);
      expect(m!.scheduledFor, DateTime(2026, 6, 4, 7, 0));
    });

    test('feuert NICHT bei anderer Schicht', () {
      final specs = _run(now: DateTime(2026, 6, 4, 5, 30), shift: 'Nacht');
      expect(_byCategory(specs, NotificationCategory.morningLight), isNull);
    });

    test('feuert NICHT nach 9 Uhr', () {
      final specs = _run(now: DateTime(2026, 6, 4, 10, 0), shift: 'Früh');
      expect(_byCategory(specs, NotificationCategory.morningLight), isNull);
    });
  });

  group('Invarianten', () {
    test('keine doppelten IDs / keine doppelten Kategorien', () {
      // Konstellation, die mehrere Nudges gleichzeitig ausloest.
      final specs = _run(
        now: DateTime(2026, 6, 4, 8, 0),
        shift: 'Früh',
        dailyWaterMl: 100,
        waterGoalMl: 2500,
        caffeineDay: _withCoffee(DateTime(2026, 6, 4, 5, 30)),
        lastBedtimeMinutes: 23 * 60,
        stats: _stats(
          currentStreak: 4,
          lastWorkoutDate: DateTime(2026, 6, 3),
        ),
      );
      final ids = specs.map((s) => s.id).toList();
      expect(ids.toSet().length, ids.length, reason: 'IDs muessen unique sein');
      final cats = specs.map((s) => s.category).toList();
      expect(cats.toSet().length, cats.length,
          reason: 'hoechstens ein Spec pro Kategorie');
      expect(specs.length, greaterThanOrEqualTo(4));
    });

    test('alle geplanten Zeitpunkte liegen strikt nach now', () {
      final now = DateTime(2026, 6, 4, 8, 0);
      final specs = _run(
        now: now,
        shift: 'Früh',
        dailyWaterMl: 100,
        waterGoalMl: 2500,
        caffeineDay: _withCoffee(DateTime(2026, 6, 4, 5, 30)),
        lastBedtimeMinutes: 23 * 60,
        stats: _stats(
          currentStreak: 4,
          lastWorkoutDate: DateTime(2026, 6, 3),
        ),
      );
      for (final s in specs) {
        expect(s.scheduledFor.isAfter(now), isTrue,
            reason: '${s.category} darf nicht in der Vergangenheit liegen');
      }
    });

    test('Ergebnis ist nach scheduledFor aufsteigend sortiert', () {
      final specs = _run(
        now: DateTime(2026, 6, 4, 8, 0),
        shift: 'Früh',
        dailyWaterMl: 100,
        waterGoalMl: 2500,
        caffeineDay: _withCoffee(DateTime(2026, 6, 4, 5, 30)),
        lastBedtimeMinutes: 23 * 60,
        stats: _stats(
          currentStreak: 4,
          lastWorkoutDate: DateTime(2026, 6, 3),
        ),
      );
      for (var i = 1; i < specs.length; i++) {
        expect(
          specs[i - 1].scheduledFor.isAfter(specs[i].scheduledFor),
          isFalse,
        );
      }
    });

    test('leerer Tag (alles erfuellt / nichts faellig) -> keine Specs', () {
      final specs = _run(
        now: DateTime(2026, 6, 4, 12, 0),
        shift: 'Frei',
        dailyWaterMl: 2500,
        waterGoalMl: 2500,
        caffeineDay: const CaffeineDay(),
        stats: _stats(currentStreak: 0),
      );
      expect(specs, isEmpty);
    });
  });
}

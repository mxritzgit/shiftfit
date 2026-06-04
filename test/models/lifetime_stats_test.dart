import 'package:flutter_test/flutter_test.dart';

import 'package:shiftfit/src/models/lifetime_stats.dart';

// TEST-7: LifetimeStats.recordWorkoutDay — Streak-Uebergaenge.
// logic_test.dart deckt die Basisfaelle (erster Tag / gestern / idempotent /
// Luecke) ab; hier die zusaetzlichen Uebergaenge: Mehrtages-Kette,
// Datums-Normalisierung (Uhrzeit wird gestrippt), longestStreak-Monotonie
// ueber einen Reset hinweg, Zukunftsdatum als Luecke, und die Reparatur des
// currentStreak==0-Startzustands.

void main() {
  final mon = DateTime(2026, 6, 1);
  final tue = DateTime(2026, 6, 2);
  final wed = DateTime(2026, 6, 3);
  final thu = DateTime(2026, 6, 4);
  final fri = DateTime(2026, 6, 5);

  group('recordWorkoutDay', () {
    test('gestern -> +1 (aufeinanderfolgende Tage zaehlen hoch)', () {
      final s = LifetimeStats().recordWorkoutDay(mon).recordWorkoutDay(tue);
      expect(s.currentStreak, 2);
      expect(s.longestStreak, 2);
      expect(s.lastWorkoutDate, tue);
    });

    test('mehrtaegige Kette Mo..Fr -> Streak 5', () {
      final s = LifetimeStats()
          .recordWorkoutDay(mon)
          .recordWorkoutDay(tue)
          .recordWorkoutDay(wed)
          .recordWorkoutDay(thu)
          .recordWorkoutDay(fri);
      expect(s.currentStreak, 5);
      expect(s.longestStreak, 5);
      expect(s.lastWorkoutDate, fri);
    });

    test('heute erneut -> idempotent, Streak haelt (kein Doppel-Zaehlen)', () {
      final s = LifetimeStats()
          .recordWorkoutDay(mon)
          .recordWorkoutDay(tue) // Streak 2
          .recordWorkoutDay(tue); // selber Tag nochmal
      expect(s.currentStreak, 2);
      expect(s.longestStreak, 2);
    });

    test('idempotent auch bei abweichender Uhrzeit am selben Kalendertag', () {
      final morning = DateTime(2026, 6, 2, 7, 15);
      final evening = DateTime(2026, 6, 2, 22, 45);
      final s = LifetimeStats()
          .recordWorkoutDay(mon)
          .recordWorkoutDay(morning) // Streak 2
          .recordWorkoutDay(evening); // gleicher Tag -> haelt
      expect(s.currentStreak, 2);
      // lastWorkoutDate ist auf date-only normalisiert (Mitternacht).
      expect(s.lastWorkoutDate, DateTime(2026, 6, 2));
    });

    test('lastWorkoutDate wird immer auf date-only (00:00) normalisiert', () {
      final s = LifetimeStats().recordWorkoutDay(DateTime(2026, 6, 4, 18, 30));
      expect(s.lastWorkoutDate, DateTime(2026, 6, 4));
    });

    test('Luecke -> Reset auf 1, longestStreak bleibt der Highscore', () {
      final s = LifetimeStats()
          .recordWorkoutDay(mon)
          .recordWorkoutDay(tue)
          .recordWorkoutDay(wed) // Streak 3
          .recordWorkoutDay(fri); // do fehlt -> Luecke
      expect(s.currentStreak, 1);
      expect(s.longestStreak, 3);
      expect(s.lastWorkoutDate, fri);
    });

    test('longestStreak ist monoton: neuer Lauf uebertrifft alten Highscore', () {
      final s = LifetimeStats()
          .recordWorkoutDay(mon)
          .recordWorkoutDay(tue) // Highscore 2
          .recordWorkoutDay(thu) // Reset auf 1 (Luecke)
          .recordWorkoutDay(fri); // 2 — gleich, longest bleibt 2
      expect(s.currentStreak, 2);
      expect(s.longestStreak, 2);

      // Noch ein Tag dran -> 3 > alter Highscore 2.
      final s2 = s.recordWorkoutDay(DateTime(2026, 6, 6));
      expect(s2.currentStreak, 3);
      expect(s2.longestStreak, 3);
    });

    test('Zukunftsdatum (>1 Tag voraus) wird wie eine Luecke behandelt', () {
      final s = LifetimeStats()
          .recordWorkoutDay(mon)
          .recordWorkoutDay(fri); // 4 Tage voraus
      expect(s.currentStreak, 1);
      expect(s.lastWorkoutDate, fri);
    });

    test('aus geladenem Zustand mit currentStreak 0 fortsetzen -> repariert auf >= 1',
        () {
      // Defensive Branch: wenn ein alter/inkonsistenter Datensatz
      // lastWorkoutDate gesetzt aber currentStreak 0 hat, darf derselbe Tag
      // nicht 0 lassen.
      final loaded = LifetimeStats(currentStreak: 0, lastWorkoutDate: tue);
      final same = loaded.recordWorkoutDay(tue); // gleicher Tag
      expect(same.currentStreak, 1);

      final next = loaded.recordWorkoutDay(wed); // Folgetag
      expect(next.currentStreak, 1); // 0 + 1
    });

    test('andere Zaehler bleiben unberuehrt', () {
      final s = LifetimeStats(workoutsCompleted: 9, mealsLogged: 40)
          .recordWorkoutDay(mon);
      expect(s.workoutsCompleted, 9);
      expect(s.mealsLogged, 40);
      expect(s.currentStreak, 1);
    });
  });
}

import '../models/caffeine_entry.dart';
import '../models/lifetime_stats.dart';

/// Fachliche Kategorie eines geplanten Nudges. Bewusst entkoppelt von der
/// UI-Farb-/Icon-Welt (SmartRemindersCard kennt cyan/orange/...), damit diese
/// Engine flutter-frei und damit rein unit-testbar bleibt. Das Mapping auf
/// Channels/Icons passiert spaeter im NotificationService bzw. der UI.
enum NotificationCategory { hydration, caffeine, sleep, morningLight, streak }

/// Ein vollstaendig aufgeloester, plan-fertiger Notification-Spec. Reiner
/// Wert-Typ (immutable, mit Gleichheit), den der NotificationService 1:1 an
/// zonedSchedule weiterreichen kann. Keine Flutter-/IO-Abhaengigkeit.
class NotificationSpec {
  const NotificationSpec({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledFor,
    required this.category,
  });

  /// Stabile, deterministische Plattform-ID (siehe [NotificationContentEngine]
  /// fuer den ID-Raum). Gleiche Eingaben -> gleiche IDs, damit ein erneutes
  /// scheduleAll alte Eintraege ueberschreibt statt zu duplizieren.
  final int id;
  final String title;
  final String body;

  /// Wandzeit (lokale Zone), zu der der Nudge feuern soll. Liegt IMMER in der
  /// Zukunft relativ zum uebergebenen `now` (Engine plant nichts in die
  /// Vergangenheit).
  final DateTime scheduledFor;
  final NotificationCategory category;

  @override
  bool operator ==(Object other) =>
      other is NotificationSpec &&
      other.id == id &&
      other.title == title &&
      other.body == body &&
      other.scheduledFor == scheduledFor &&
      other.category == category;

  @override
  int get hashCode => Object.hash(id, title, body, scheduledFor, category);

  @override
  String toString() =>
      'NotificationSpec(id: $id, category: $category, '
      'scheduledFor: $scheduledFor, title: "$title")';
}

/// PURE, deterministische Heuristik-Engine fuer lokale Retention-Nudges.
///
/// Extrahiert aus [SmartRemindersCard] (lib/src/widgets/today/), aber bewusst
/// als eigenstaendige, flutter-/IO-freie Klasse:
///   * `now` wird IMMER als Parameter hereingereicht (kein DateTime.now()),
///   * keine Plattform-Calls, keine Farben/Icons, keine Persistenz,
/// damit das Verhalten 1:1 unit-testbar ist (siehe
/// test/notification_content_engine_test.dart).
///
/// Wo die Card "jetzt zeigen, wenn Bedingung jetzt wahr" macht, plant die
/// Engine "feuere zum naechsten passenden Zeitpunkt" — dieselben Schwellen,
/// nur in die Zukunft projiziert. Zusaetzlich der NEUE abendliche
/// Streak-at-risk-Nudge, den die Card nicht hat.
class NotificationContentEngine {
  const NotificationContentEngine();

  // --- Stabiler ID-Raum -----------------------------------------------------
  // Feste IDs pro Kategorie. Jede Kategorie plant hoechstens EINEN Spec pro
  // Lauf, deshalb genuegt je eine konstante ID. Ein erneutes scheduleAll mit
  // denselben IDs ueberschreibt den vorherigen Plan (kein Doppel-Feuern).
  static const int idHydration = 9001;
  static const int idCaffeine = 9002;
  static const int idSleep = 9003;
  static const int idMorningLight = 9004;
  static const int idStreak = 9005;

  /// Plant die heute/zeitnah faelligen Nudges relativ zu [now].
  ///
  /// Parameter spiegeln exakt die Eingaben der SmartRemindersCard plus die
  /// Streak-Daten aus [LifetimeStats]:
  ///   * [shift] — aktuelle Schicht ('Frueh'/'Spaet'/'Nacht'/'Frei'),
  ///   * [dailyWaterMl]/[waterGoalMl] — Hydrations-Fortschritt,
  ///   * [caffeineDay] — heutige Koffein-Eintraege (Cutoff-Logik),
  ///   * [lastBedtimeMinutes]/[sleepGoalMinutes] — Schlaf-Runway,
  ///   * [stats] — Streak + lastWorkoutDate fuer den Abend-Nudge.
  ///
  /// Liefert eine deterministische, ueberlappungsfreie Liste (eine pro
  /// Kategorie), sortiert nach [NotificationSpec.scheduledFor]. Alle Specs
  /// liegen strikt nach [now].
  List<NotificationSpec> buildSchedule({
    required DateTime now,
    required String shift,
    required int dailyWaterMl,
    required int waterGoalMl,
    required CaffeineDay caffeineDay,
    int? lastBedtimeMinutes,
    required int sleepGoalMinutes,
    required LifetimeStats stats,
  }) {
    final specs = <NotificationSpec>[];

    final hydration = _hydration(now, dailyWaterMl, waterGoalMl);
    if (hydration != null) specs.add(hydration);

    final caffeine = _caffeine(now, shift, caffeineDay);
    if (caffeine != null) specs.add(caffeine);

    final sleep = _sleep(now, lastBedtimeMinutes);
    if (sleep != null) specs.add(sleep);

    final morning = _morningLight(now, shift);
    if (morning != null) specs.add(morning);

    final streak = _streakAtRisk(now, stats);
    if (streak != null) specs.add(streak);

    specs.sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
    return specs;
  }

  // --- Hydration -------------------------------------------------------------
  // Card: zeigt ab 11:00, wenn Wasser < 40% des Ziels. Engine: plant einen
  // Nudge auf 11:00 (oder sofort > now, falls schon nach 11), SOLANGE der
  // aktuelle Stand < 40% ist. Liegt 11:00 heute schon in der Vergangenheit und
  // ist das Ziel noch nicht annaehernd erreicht, feuert er zur naechsten vollen
  // Stunde — so kommt der Reminder auch nachmittags noch.
  NotificationSpec? _hydration(DateTime now, int dailyWaterMl, int waterGoalMl) {
    if (waterGoalMl <= 0) return null;
    final threshold = (waterGoalMl * 0.4).round();
    if (dailyWaterMl >= threshold) return null;

    final eleven = DateTime(now.year, now.month, now.day, 11);
    DateTime when;
    if (now.isBefore(eleven)) {
      when = eleven;
    } else if (now.hour >= 21) {
      // Spaet am Tag lohnt sich der Nudge nicht mehr — Tag fast vorbei.
      return null;
    } else {
      // Naechste volle Stunde, mindestens eine Minute in der Zukunft.
      when = DateTime(now.year, now.month, now.day, now.hour + 1);
    }
    final missing = waterGoalMl - dailyWaterMl;
    return NotificationSpec(
      id: idHydration,
      title: 'Wasser nachlegen',
      body: 'Noch $missing ml bis zum Tagesziel.',
      scheduledFor: when,
      category: NotificationCategory.hydration,
    );
  }

  // --- Koffein-Cutoff --------------------------------------------------------
  // Card: zeigt im 60-Min-Fenster vor dem Cutoff, wenn heute Koffein getrunken
  // wurde. Engine: plant den Nudge punktgenau auf (Cutoff - 60 Min), sofern
  // dieser Zeitpunkt noch in der Zukunft liegt und heute schon Koffein lief.
  NotificationSpec? _caffeine(DateTime now, String shift, CaffeineDay day) {
    if (day.entries.isEmpty) return null;
    final cutoff = _cutoffMinutes(shift);
    final warnMinutes = cutoff - 60;
    final when = _dayStart(now).add(Duration(minutes: warnMinutes));
    if (!when.isAfter(now)) return null;
    return NotificationSpec(
      id: idCaffeine,
      title: 'Koffein-Stopp bald',
      body: 'Letzte Tasse vor ${_label(cutoff)} hilft dem Schlaf.',
      scheduledFor: when,
      category: NotificationCategory.caffeine,
    );
  }

  // --- Schlaf-Runway ---------------------------------------------------------
  // Card: zeigt 90 Min vor der (zuletzt geloggten) Bettzeit. Engine: plant den
  // Nudge exakt auf (Bettzeit - 90 Min). Bettzeit wird wie in der Card ggf. um
  // 24h nach vorne gewickelt (Bettzeit nach Mitternacht).
  NotificationSpec? _sleep(DateTime now, int? lastBedtimeMinutes) {
    if (lastBedtimeMinutes == null) return null;
    final mins = now.hour * 60 + now.minute;
    var bedtime = lastBedtimeMinutes;
    if (bedtime <= mins) {
      bedtime += 24 * 60;
    }
    const prepLeadMinutes = 90;
    final prepStart = bedtime - prepLeadMinutes;
    final when = _dayStart(now).add(Duration(minutes: prepStart));
    if (!when.isAfter(now)) return null;
    return NotificationSpec(
      id: idSleep,
      title: 'Schlaf-Runway',
      body: 'In $prepLeadMinutes Min ins Bett — Licht dimmen, Screens weg.',
      scheduledFor: when,
      category: NotificationCategory.sleep,
    );
  }

  // --- Morgen-Tageslicht (schichtspezifisch) ---------------------------------
  // Card: zeigt vor 9:00 bei Frueh-Schicht. Engine: plant einen Anker auf
  // 07:00 (oder > now, falls schon nach 7), solange es vor 9:00 ist.
  NotificationSpec? _morningLight(DateTime now, String shift) {
    if (shift != 'Frueh' && shift != 'Früh') return null;
    if (now.hour >= 9) return null;
    final seven = DateTime(now.year, now.month, now.day, 7);
    final when = now.isBefore(seven)
        ? seven
        : DateTime(now.year, now.month, now.day, now.hour, now.minute)
            .add(const Duration(minutes: 1));
    return NotificationSpec(
      id: idMorningLight,
      title: 'Tageslicht',
      body: '10 Min Sonne vor der Schicht stabilisiert den Rhythmus.',
      scheduledFor: when,
      category: NotificationCategory.morningLight,
    );
  }

  // --- NEU: Abendlicher Streak-at-risk-Nudge ---------------------------------
  // Feuert NUR, wenn eine aktive Streak laeuft (currentStreak >= 1) UND heute
  // noch KEIN Workout verbucht wurde (lastWorkoutDate != heute). Plant auf
  // 19:00 lokal; ist es schon nach 19:00 (aber vor dem Tagesende), feuert er
  // sofort zur naechsten Minute, damit der Tag nicht ungenutzt verstreicht.
  NotificationSpec? _streakAtRisk(DateTime now, LifetimeStats stats) {
    if (stats.currentStreak < 1) return null;
    final last = stats.lastWorkoutDate;
    if (last != null &&
        last.year == now.year &&
        last.month == now.month &&
        last.day == now.day) {
      // Heute schon trainiert — Streak ist sicher, kein Nudge.
      return null;
    }
    final evening = DateTime(now.year, now.month, now.day, 19);
    DateTime when;
    if (now.isBefore(evening)) {
      when = evening;
    } else if (now.hour >= 23) {
      // Zu kurz vor Mitternacht — Reminder kaeme zu spaet, um zu wirken.
      return null;
    } else {
      when = now.add(const Duration(minutes: 1));
    }
    return NotificationSpec(
      id: idStreak,
      title: 'Streak halten',
      body: 'Dein ${stats.currentStreak}-Tage-Streak wartet — noch ein '
          'kurzes Workout heute zaehlt.',
      scheduledFor: when,
      category: NotificationCategory.streak,
    );
  }

  // --- Helpers (1:1 aus SmartRemindersCard) ----------------------------------
  DateTime _dayStart(DateTime now) => DateTime(now.year, now.month, now.day);

  int _cutoffMinutes(String shift) {
    switch (shift) {
      case 'Nacht':
        return 26 * 60;
      case 'Spät':
      case 'Spaet':
        return 18 * 60;
      case 'Frei':
        return 14 * 60;
      default:
        return 13 * 60;
    }
  }

  String _label(int minutes) {
    final h = (minutes ~/ 60) % 24;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}

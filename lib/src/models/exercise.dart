/// Eine Uebung aus der seeded Uebungs-Bibliothek (PROD-5).
///
/// Bewusst minimal: id (stabiler Slug, landet als `exercise`-Spalte in
/// public.workout_sets), Anzeigename und Muskelgruppe. Die Bibliothek ist
/// eine const-Liste — kein I/O, keine DB-Tabelle. Spiegelt den Stil der
/// uebrigen Domain-Modelle (immutable, const-Konstruktor).
class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
  });

  /// Stabiler Slug (`bench_press`, `squat` …). Wird als Konflikt-/Filter-
  /// Schluessel verwendet und in der workout_sets.exercise-Spalte abgelegt.
  final String id;

  /// Anzeigename in der UI (deutsch).
  final String name;

  /// Grobe Muskelgruppe fuer Gruppierung/Anzeige (deutsch).
  final String muscleGroup;

  /// Findet eine Uebung der Bibliothek per [id]; null wenn unbekannt
  /// (z.B. eine alte gespeicherte Zeile mit einem entfernten Slug).
  static Exercise? byId(String id) {
    for (final e in exerciseLibrary) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// Anzeigename fuer eine gespeicherte exercise-id; faellt auf einen
  /// lesbaren Fallback (Slug mit Leerzeichen) zurueck, wenn der Slug nicht
  /// (mehr) in der Bibliothek ist — so bleibt eine alte Log-Zeile lesbar.
  static String displayName(String id) {
    final found = byId(id);
    if (found != null) return found.name;
    if (id.isEmpty) return 'Übung';
    return id.replaceAll('_', ' ');
  }
}

/// Kleine kuratierte Uebungs-Bibliothek. Deckt die grossen Grundmuster ab,
/// die der Wochenplan (`Kraft`/`Muskelaufbau`) ohnehin empfiehlt — bewusst
/// kurz gehalten, additiv erweiterbar. Slugs sind stabil; einmal vergeben
/// sollten sie nicht mehr umbenannt werden (sie stehen in gespeicherten
/// Log-Zeilen).
const List<Exercise> exerciseLibrary = <Exercise>[
  Exercise(id: 'squat', name: 'Kniebeuge', muscleGroup: 'Beine'),
  Exercise(id: 'deadlift', name: 'Kreuzheben', muscleGroup: 'Rücken'),
  Exercise(id: 'bench_press', name: 'Bankdrücken', muscleGroup: 'Brust'),
  Exercise(id: 'overhead_press', name: 'Schulterdrücken', muscleGroup: 'Schultern'),
  Exercise(id: 'barbell_row', name: 'Langhantelrudern', muscleGroup: 'Rücken'),
  Exercise(id: 'pull_up', name: 'Klimmzug', muscleGroup: 'Rücken'),
  Exercise(id: 'lunge', name: 'Ausfallschritt', muscleGroup: 'Beine'),
  Exercise(id: 'romanian_deadlift', name: 'Rumänisches Kreuzheben', muscleGroup: 'Beinbeuger'),
  Exercise(id: 'incline_dumbbell_press', name: 'Schrägbankdrücken (KH)', muscleGroup: 'Brust'),
  Exercise(id: 'lat_pulldown', name: 'Latzug', muscleGroup: 'Rücken'),
  Exercise(id: 'leg_press', name: 'Beinpresse', muscleGroup: 'Beine'),
  Exercise(id: 'biceps_curl', name: 'Bizepscurl', muscleGroup: 'Bizeps'),
  Exercise(id: 'triceps_pushdown', name: 'Trizepsdrücken', muscleGroup: 'Trizeps'),
  Exercise(id: 'hip_thrust', name: 'Hip Thrust', muscleGroup: 'Gesäß'),
  Exercise(id: 'plank', name: 'Plank', muscleGroup: 'Core'),
];

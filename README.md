# FitPilot

FitPilot ist eine Flutter-App für klare FitnessPläne, Training, Recovery und Ernährung.

Die App bündelt aktuell diese Bereiche:
- Heute-Dashboard mit Check-in für Trainingsziel, Energie und Belastung
- Wochenplaner für den Trainingssplit
- Trends/Readiness-Ansicht
- Meal-Analyse per Foto und Barcode

## Projektziel

FitPilot soll Training, Regeneration und Ernährung alltagstauglich steuern: kurze, evidenzbasierte Pläne statt überladener Fitness-Tracker.

## Code-Struktur

Der App-Code liegt jetzt bewusst nicht mehr gesammelt in `lib/main.dart`, sondern sauber unter `lib/src/`.

```text
lib/
├── main.dart
└── src/
    ├── app/
    │   ├── shiftfit_app.dart
    │   └── shiftfit_home_page.dart
    ├── models/
    │   ├── meal_analysis_request.dart
    │   ├── meal_analysis_result.dart
    │   ├── plan_block.dart
    │   └── shift_fit_plan.dart
    ├── screens/
    │   ├── barcode_scanner_screen.dart
    │   ├── meal_analysis_screen.dart
    │   ├── today_dashboard.dart
    │   ├── trends_screen.dart
    │   └── week_planner_screen.dart
    ├── services/
    │   ├── meal_analyzer.dart
    │   └── open_food_facts_product_service.dart
    ├── theme/
    │   ├── app_colors.dart
    │   └── app_theme.dart
    └── widgets/
        ├── app_shell/
        ├── common/
        ├── meal/
        ├── shared/
        ├── today/
        ├── trends/
        └── week/
```

## Verantwortlichkeiten

### `lib/main.dart`
Kleiner Entry-Point. Startet die App und exportiert `ShiftFitApp` für Tests.

### `lib/src/app/`
App-Shell und zentraler Screen-Aufbau.
- `shiftfit_app.dart`: `MaterialApp`, Theme, Startscreen
- `shiftfit_home_page.dart`: Tab-State, Auswahl-State und Routing zwischen den Hauptbereichen

### `lib/src/models/`
Reine Datenmodelle und Mapping-Logik.
- Trainings-/Recovery-Plan
- Meal-Analyse Request/Response
- Plan-Blöcke

### `lib/src/screens/`
Top-Level Screens mit State und Ablaufsteuerung.
- Heute
- Woche
- Trends
- Analyse
- Barcode-Scanner

### `lib/src/services/`
Anbindungen an externe Datenquellen oder Analyse-Logik.
- Meal Analyzer
- OpenFoodFacts Barcode Lookup

### `lib/src/theme/`
Zentrale Farben und App-Theme.

### `lib/src/widgets/`
Wiederverwendbare UI-Bausteine.
- `common/`: generische Widgets
- `shared/`: app-übergreifende Widgets
- `today/`, `week/`, `trends/`, `meal/`: bereichsspezifische UI-Bausteine
- `app_shell/`: Navigation / Shell-Widgets

## Regeln für künftige Änderungen

Damit die Struktur sauber bleibt:
- Neue Screens in `lib/src/screens/`
- Wiederverwendbare UI in `lib/src/widgets/`
- Reine Datenobjekte in `lib/src/models/`
- Externe API-/Service-Logik in `lib/src/services/`
- Farben und Theme nur zentral in `lib/src/theme/`
- `lib/main.dart` klein halten

## Lokale Entwicklung

`SUPABASE_URL` und `SUPABASE_ANON_KEY` werden zur Build-Zeit injiziert,
nicht aus dem Sourcecode gelesen. Lege dir einmalig deine eigene
`dart_defines.json` (gitignored) neben `pubspec.yaml`:

```bash
cp dart_defines.example.json dart_defines.json
# Werte in dart_defines.json eintragen (Anon-Key aus Supabase-Dashboard)
```

Danach:

```bash
flutter pub get
flutter analyze
flutter test --dart-define-from-file=dart_defines.json
flutter run --dart-define-from-file=dart_defines.json
```

Ohne die Defines wirft `FitPilotSupabaseConfig.initialize()` einen
`StateError` beim App-Start — Absicht, damit ein versehentlicher Build
ohne Konfiguration nicht still gegen ein falsches Projekt laeuft.

## Security

CI-Checks laufen in `.github/workflows/security.yml`: `flutter analyze`,
`flutter test`, `flutter pub outdated`, OSV-Scanner gegen `pubspec.lock`
und `deno lint`/`deno check` fuer die Edge Functions. Zusaetzlich
wöchentlich (Montag 06:00 UTC) per Cron, damit frisch publizierte CVEs
nicht unentdeckt liegen.

**Key-Rotation (einmalig nach diesem Commit empfohlen):** Der bisherige
`SUPABASE_ANON_KEY` stand im Klartext in `lib/src/config/supabase_config.dart`
und liegt damit weiter in der Git-History. Anon-Key ist kein Secret im
engeren Sinn (JWT mit `role: anon`, im Client-Bundle ohnehin extrahierbar)
— rotieren erhoeht trotzdem die Huerde fuer automatisierten Abuse:

1. Supabase-Dashboard → Project Settings → API → "Roll anon key"
2. Neuen Key in `dart_defines.json` eintragen (lokal)
3. Falls produktive Builds existieren: neu bauen + ausrollen

## Test-Hinweis

`package:shiftfit/main.dart` exportiert weiterhin `ShiftFitApp`, damit Widget-Tests stabil bleiben.

## Nächste sinnvolle Richtung

Wenn FitPilot weiter wächst, können wir als Nächstes zusätzlich sauber trennen in:
- `features/` statt rein nach Dateityp
- persistente State-Schicht
- echte Repository-/Data-Layer für externe Quellen
- kleinere Widget-Dateien innerhalb einzelner Features

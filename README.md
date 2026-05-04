# ShiftFit

ShiftFit ist eine Flutter-App für Fitness und Recovery im Schichtdienst.

Die App bündelt aktuell diese Bereiche:
- Heute-Dashboard mit Check-in für Schicht, Energie und Stress
- Wochenplaner für den Schichtrhythmus
- Trends/Readiness-Ansicht
- Meal-Analyse per Foto und Barcode

## Projektziel

ShiftFit soll Menschen mit Früh-, Spät- und Nachtschichten helfen, Training, Regeneration und Ernährung alltagstauglich zu steuern.

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

Beispiel:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Test-Hinweis

`package:shiftfit/main.dart` exportiert weiterhin `ShiftFitApp`, damit Widget-Tests stabil bleiben.

## Nächste sinnvolle Richtung

Wenn ShiftFit weiter wächst, können wir als Nächstes zusätzlich sauber trennen in:
- `features/` statt rein nach Dateityp
- persistente State-Schicht
- echte Repository-/Data-Layer für externe Quellen
- kleinere Widget-Dateien innerhalb einzelner Features

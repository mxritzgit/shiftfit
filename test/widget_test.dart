import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:shiftfit/main.dart';
import 'package:shiftfit/src/models/meal_analysis_request.dart';
import 'package:shiftfit/src/models/meal_analysis_result.dart';
import 'package:shiftfit/src/models/meal_component.dart';
import 'package:shiftfit/src/services/meal_analyzer.dart';
import 'package:shiftfit/src/services/meal_photo_input.dart';

void main() {
  testWidgets('ShiftFit dashboard shows the expanded start experience', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ShiftFitApp());

    expect(find.text('ShiftFit'), findsOneWidget);
    expect(find.text('Train smart.\nRecover better.'), findsOneWidget);
    expect(
      find.text('Kurze Empfehlungen passend zu deiner Schicht.'),
      findsOneWidget,
    );
    expect(find.text('Heute'), findsWidgets);
    expect(find.text('20 Min Training'), findsOneWidget);
    expect(find.text('Plan öffnen'), findsOneWidget);
    expect(find.text('Recovery Score'), findsOneWidget);
    expect(find.text('Dein Plan für heute'), findsOneWidget);
    expect(find.text('Schicht-Kompass'), findsOneWidget);
    expect(find.text('Recovery Tools'), findsOneWidget);
    expect(find.text('Wochenrhythmus'), findsOneWidget);
    expect(find.text('Sleep Anchor'), findsOneWidget);
    expect(find.text('Fuel Reminder'), findsOneWidget);
    expect(find.text('Breath Reset'), findsOneWidget);
    expect(find.text('Schichtarbeit. Training. Recovery.'), findsOneWidget);
  });

  testWidgets('Check-in updates recommendation for fatigue, night and strong energy', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ShiftFitApp());

    await tester.ensureVisible(find.byKey(const ValueKey('option-Müde')));
    await tester.tap(find.byKey(const ValueKey('option-Müde')));
    await tester.pumpAndSettle();
    expect(find.text('Recovery Flow'), findsOneWidget);
    expect(find.text('Runterfahren statt durchbeißen'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('option-Normal')));
    await tester.tap(find.byKey(const ValueKey('option-Normal')));
    await tester.ensureVisible(find.byKey(const ValueKey('option-Nacht')));
    await tester.tap(find.byKey(const ValueKey('option-Nacht')));
    await tester.pumpAndSettle();
    expect(find.text('Mobility Reset'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('option-Stark')));
    await tester.tap(find.byKey(const ValueKey('option-Stark')));
    await tester.pumpAndSettle();
    expect(find.text('Kraft Session'), findsOneWidget);
  });

  testWidgets('Plan sheet can be opened from today card', (WidgetTester tester) async {
    await tester.pumpWidget(const ShiftFitApp());

    await tester.ensureVisible(find.byKey(const ValueKey('today-open-plan')));
    await tester.tap(find.byKey(const ValueKey('today-open-plan')));
    await tester.pumpAndSettle();

    expect(find.text('Für heute vormerken'), findsOneWidget);
    expect(find.textContaining('Warm-up'), findsWidgets);
  });

  testWidgets('Bottom navigation switches between Heute, Woche, Trends and Analyse', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ShiftFitApp());

    expect(find.text('Train smart.\nRecover better.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-Woche')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('screen-week')), findsOneWidget);
    expect(find.text('7 Tage,\nsauber getaktet.'), findsOneWidget);
    expect(find.text('Schichtplan'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-Trends')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('screen-trends')), findsOneWidget);
    expect(find.text('Readiness bleibt\nsteuerbar.'), findsOneWidget);
    expect(find.text('Readiness Verlauf'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-Analyse')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('screen-analyse')), findsOneWidget);
    expect(find.byKey(const ValueKey('analyse-hero-title')), findsOneWidget);
    expect(find.text('Mahlzeit scannen'), findsOneWidget);
    expect(find.byKey(const ValueKey('analyse-barcode-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('analyse-daily-kcal-card')), findsOneWidget);
    expect(find.text('Barcode scannen'), findsOneWidget);
    expect(find.text('Demo-Fotoanalyse'), findsNothing);
    expect(find.text('Demo-Barcode laden'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('nav-Heute')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('screen-today')), findsOneWidget);
    expect(find.text('Train smart.\nRecover better.'), findsOneWidget);
  });

  testWidgets('Analyse tab supports deterministic itemized photo results and daily kcal adding', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ShiftFitApp(
        mealAnalyzer: _FakeMealAnalyzer(),
        photoInput: _FakeMealPhotoInput(),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('nav-Analyse')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('analyse-daily-kcal-total')), findsOneWidget);
    expect(find.text('0 kcal'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('analyse-camera-button')));
    await tester.pump();
    expect(find.byKey(const ValueKey('analyse-loading')), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('analyse-result-card')), findsOneWidget);
    expect(find.text('Kartoffeln'), findsOneWidget);
    expect(find.text('Steak'), findsOneWidget);
    expect(find.text('Brokkoli'), findsOneWidget);
    expect(find.byKey(const ValueKey('analyse-item-breakdown')), findsOneWidget);
    expect(find.text('855 kcal'), findsWidgets);

    await tester.ensureVisible(find.byKey(const ValueKey('analyse-add-daily-button')));
    await tester.tap(find.byKey(const ValueKey('analyse-add-daily-button')));
    await tester.pumpAndSettle();
    expect(find.text('Zu heute hinzugefügt'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('analyse-daily-kcal-card')),
        matching: find.text('855 kcal'),
      ),
      findsOneWidget,
    );

    await tester.ensureVisible(find.byKey(const ValueKey('analyse-adjust-button')));
    await tester.tap(find.byKey(const ValueKey('analyse-adjust-button')));
    await tester.pumpAndSettle();
    expect(find.text('Bestandteile anpassen'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('analyse-item-weight-input-0')),
      '150',
    );
    await tester.pumpAndSettle();
    expect(find.text('550 g ≈ 815 kcal'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('analyse-save-weight-button')));
    await tester.pumpAndSettle();
    expect(find.text('815 kcal'), findsWidgets);
    expect(find.textContaining('550 g über Einzelposten angepasst'), findsOneWidget);
    expect(find.text('Zu heute hinzugefügt'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('analyse-daily-kcal-card')),
        matching: find.text('815 kcal'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Week planner updates a day shift and summaries', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ShiftFitApp());

    await tester.tap(find.byKey(const ValueKey('nav-Woche')));
    await tester.pumpAndSettle();

    expect(find.text('1 geplant'), findsOneWidget);
    expect(find.text('4 Tage'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('week-Mo-Nacht')));
    await tester.pumpAndSettle();

    expect(find.text('2 geplant'), findsOneWidget);
    expect(find.text('3 Tage'), findsOneWidget);
  });
}

class _FakeMealAnalyzer implements MealAnalyzer {
  @override
  Future<MealAnalysisResult> analyze(MealAnalysisRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return const MealAnalysisResult(
      mealName: 'Teller mit Steak, Kartoffeln und Brokkoli',
      caloriesKcal: 855,
      estimatedGrams: 600,
      kcalPer100G: 142.5,
      protein: '64 g',
      carbs: '42 g',
      fat: '38 g',
      confidence: 'Mittel',
      portionNotes:
          'Die KI hat sichtbare Bestandteile getrennt geschätzt. Bitte Gramm pro Bestandteil bestätigen.',
      sourceLabel: 'Foto-KI',
      items: [
        MealComponent(
          name: 'Kartoffeln',
          grams: 200,
          caloriesKcal: 160,
          kcalPer100G: 80,
        ),
        MealComponent(
          name: 'Steak',
          grams: 300,
          caloriesKcal: 660,
          kcalPer100G: 220,
        ),
        MealComponent(
          name: 'Brokkoli',
          grams: 100,
          caloriesKcal: 35,
          kcalPer100G: 35,
        ),
      ],
    );
  }
}

class _FakeMealPhotoInput implements MealPhotoInput {
  @override
  Future<MealPhotoSelection?> pick(ImageSource source) async {
    return const MealPhotoSelection(
      request: MealAnalysisRequest(imageId: 'test-photo'),
      previewBytes: null,
    );
  }
}

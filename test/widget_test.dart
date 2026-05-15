import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:shiftfit/main.dart';
import 'package:shiftfit/src/models/meal_analysis_request.dart';
import 'package:shiftfit/src/models/meal_analysis_result.dart';
import 'package:shiftfit/src/models/meal_component.dart';
import 'package:shiftfit/src/services/meal_analyzer.dart';
import 'package:shiftfit/src/services/meal_photo_input.dart';
import 'package:shiftfit/src/services/open_food_facts_product_service.dart';

void main() {
  testWidgets('FitPilot today screen is focused and iOS-polished', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ShiftFitApp());

    expect(find.text('FitPilot'), findsOneWidget);
    expect(find.byKey(const ValueKey('screen-today')), findsOneWidget);
    expect(find.byKey(const ValueKey('today-ios-hero')), findsOneWidget);
    expect(find.byKey(const ValueKey('today-micro-checkin')), findsOneWidget);
    expect(find.byKey(const ValueKey('daily-tracker-card')), findsOneWidget);
    expect(find.byKey(const ValueKey('today-session-card')), findsOneWidget);
    expect(find.byKey(const ValueKey('fitpilot-hub-grid')), findsOneWidget);
    expect(find.byKey(const ValueKey('weekly-challenge-card')), findsOneWidget);
    expect(find.text('Heute'), findsWidgets);
    expect(find.text('Hypertrophy Plan'), findsOneWidget);
    expect(find.text('Plan starten'), findsOneWidget);
    expect(find.text('Körpergefühl'), findsOneWidget);
    expect(find.text('Tageswerte'), findsOneWidget);
    expect(find.text('Session'), findsOneWidget);
    expect(find.text('Dein Fitness-Hub'), findsOneWidget);
    expect(find.text('Strong Start Week'), findsOneWidget);
    expect(find.text('Dein FitnessPlan\nfür heute.'), findsNothing);
    expect(find.text('Trainingsfokus'), findsNothing);
    expect(find.text('Coach Tools'), findsNothing);
    expect(find.text('Wochen Split'), findsNothing);
  });

  testWidgets('Check-in updates recommendation for fatigue, endurance and strong strength', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ShiftFitApp());

    await tester.ensureVisible(find.byKey(const ValueKey('option-Müde')));
    await tester.tap(find.byKey(const ValueKey('option-Müde')));
    await tester.pumpAndSettle();
    expect(find.text('Recovery & Mobility'), findsOneWidget);
    expect(find.text('Deload statt durchziehen'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('option-Normal')));
    await tester.tap(find.byKey(const ValueKey('option-Normal')));
    await tester.ensureVisible(find.byKey(const ValueKey('option-Ausdauer')));
    await tester.tap(find.byKey(const ValueKey('option-Ausdauer')));
    await tester.pumpAndSettle();
    expect(find.text('Cardio Engine'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('option-Kraft')));
    await tester.tap(find.byKey(const ValueKey('option-Kraft')));
    await tester.ensureVisible(find.byKey(const ValueKey('option-Stark')));
    await tester.tap(find.byKey(const ValueKey('option-Stark')));
    await tester.pumpAndSettle();
    expect(find.text('Strength Builder'), findsOneWidget);
  });

  testWidgets('Plan sheet can be opened from today card', (WidgetTester tester) async {
    await tester.pumpWidget(const ShiftFitApp());

    await tester.ensureVisible(find.byKey(const ValueKey('today-open-plan')));
    await tester.tap(find.byKey(const ValueKey('today-open-plan')));
    await tester.pumpAndSettle();

    expect(find.text('Für heute starten'), findsOneWidget);
    expect(find.textContaining('Warm-up'), findsWidgets);
  });

  testWidgets('Bottom navigation switches between Heute, Training, Trends and Food', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ShiftFitApp());

    expect(find.text('Hypertrophy Plan'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-Training')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('screen-week')), findsOneWidget);
    expect(find.text('Trainingswoche,\nsmart geplant.'), findsOneWidget);
    expect(find.text('Trainingssplit'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-Trends')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('screen-trends')), findsOneWidget);
    expect(find.text('Fortschritt bleibt\nsichtbar.'), findsOneWidget);
    expect(find.text('Progress Verlauf'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-Food')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('screen-kcal-tracker')), findsOneWidget);
    expect(find.byKey(const ValueKey('analyse-daily-kcal-card')), findsOneWidget);
    expect(find.byKey(const ValueKey('analyse-daily-kcal-total')), findsOneWidget);
    expect(find.byKey(const ValueKey('analyse-camera-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('analyse-gallery-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('analyse-barcode-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('kcal-product-search-card')), findsOneWidget);
    expect(find.text('Barcode'), findsOneWidget);
    expect(find.text('Demo-Fotoanalyse'), findsNothing);
    expect(find.text('Demo-Barcode laden'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('nav-Heute')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('screen-today')), findsOneWidget);
    expect(find.text('Hypertrophy Plan'), findsOneWidget);
  });

  testWidgets('Food tab supports deterministic itemized photo results and daily kcal adding', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ShiftFitApp(
        mealAnalyzer: _FakeMealAnalyzer(),
        photoInput: _FakeMealPhotoInput(),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('nav-Food')));
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

  testWidgets('Food tab searches OpenFoodFacts products and adds selected item', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ShiftFitApp(productService: _FakeProductLookupService()),
    );

    await tester.tap(find.byKey(const ValueKey('nav-Food')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('kcal-product-search-input')),
      'Dr Oetker Salami',
    );
    await tester.tap(find.byKey(const ValueKey('kcal-product-search-button')));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.textContaining('Dr. Oetker'), findsWidgets);
    expect(find.byKey(const ValueKey('kcal-product-suggestion-0')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('kcal-product-suggestion-0')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('analyse-result-card')), findsOneWidget);
    expect(find.textContaining('Die Ofenfrische Salami'), findsWidgets);
    expect(find.text('252 kcal'), findsWidgets);

    await tester.ensureVisible(find.byKey(const ValueKey('analyse-add-daily-button')));
    await tester.tap(find.byKey(const ValueKey('analyse-add-daily-button')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('analyse-daily-kcal-card')),
        matching: find.text('252 kcal'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Kcal product search shows suggestions while typing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ShiftFitApp(productService: _FakeProductLookupService()),
    );

    await tester.tap(find.byKey(const ValueKey('nav-Food')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('kcal-product-search-input')),
      'Dr Oetker',
    );
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('kcal-product-suggestion-0')), findsOneWidget);
    expect(find.textContaining('Dr. Oetker'), findsWidgets);
  });

  testWidgets('Kcal live product search waits through transient failures', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ShiftFitApp(productService: _FlakyProductLookupService()),
    );

    await tester.tap(find.byKey(const ValueKey('nav-Food')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('kcal-product-search-input')),
      'Dr Oetker',
    );
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.text('OpenFoodFacts-Suche gerade nicht erreichbar.'), findsNothing);

    await tester.pump(const Duration(milliseconds: 3600));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('kcal-product-suggestion-0')), findsOneWidget);
    expect(find.textContaining('Dr. Oetker'), findsWidgets);
    expect(find.text('OpenFoodFacts-Suche gerade nicht erreichbar.'), findsNothing);
  });

  testWidgets('Kcal live product search retries temporary empty results', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ShiftFitApp(productService: _EmptyThenSuccessProductLookupService()),
    );

    await tester.tap(find.byKey(const ValueKey('nav-Food')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('kcal-product-search-input')),
      'Wagner Salami',
    );
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pump(const Duration(milliseconds: 20));

    expect(
      find.text('Keine passenden Produkte gefunden. Versuche Marke + Produktname.'),
      findsNothing,
    );

    await tester.pump(const Duration(milliseconds: 3600));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('kcal-product-suggestion-0')), findsOneWidget);
    expect(find.textContaining('Dr. Oetker'), findsWidgets);
    expect(
      find.text('Keine passenden Produkte gefunden. Versuche Marke + Produktname.'),
      findsNothing,
    );
  });

  testWidgets('Training tab updates weekly split and summaries', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ShiftFitApp());

    await tester.tap(find.byKey(const ValueKey('nav-Training')));
    await tester.pumpAndSettle();

    expect(find.text('3 Krafttage'), findsOneWidget);
    expect(find.text('3 Recovery'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('week-Mo-Mobility')));
    await tester.pumpAndSettle();

    expect(find.text('2 Krafttage'), findsOneWidget);
    expect(find.text('4 Recovery'), findsOneWidget);
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

class _FakeProductLookupService implements ProductLookupService {
  static final MealAnalysisResult salamiPizza = MealAnalysisResult.fromOpenFoodFacts(
    const <String, dynamic>{
      'code': '4001724012345',
      'product_name': 'Die Ofenfrische Salami',
      'brands': 'Dr. Oetker',
      'quantity': '390 g',
      'serving_quantity': 100,
      'nutriments': <String, dynamic>{
        'energy-kcal_100g': 252,
        'proteins_100g': 10,
        'carbohydrates_100g': 31,
        'fat_100g': 9,
      },
    },
    '4001724012345',
  );

  @override
  Future<MealAnalysisResult> lookupBarcode(String barcode) async => salamiPizza;

  @override
  Future<List<ProductSearchResult>> searchProducts(String query) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return productSuggestions;
  }

  static List<ProductSearchResult> get productSuggestions =>
      <ProductSearchResult>[
        ProductSearchResult(
          code: '4001724012345',
          title: 'Die Ofenfrische Salami · Dr. Oetker',
          subtitle: 'Dr. Oetker · 390 g · 252 kcal / 100 g',
          kcalPer100G: 252,
          result: salamiPizza,
        ),
      ];
}

class _FlakyProductLookupService implements ProductLookupService {
  int searchAttempts = 0;

  @override
  Future<MealAnalysisResult> lookupBarcode(String barcode) async =>
      _FakeProductLookupService.salamiPizza;

  @override
  Future<List<ProductSearchResult>> searchProducts(String query) async {
    searchAttempts++;
    if (searchAttempts <= 2) {
      throw Exception('temporary OpenFoodFacts failure');
    }
    return _FakeProductLookupService.productSuggestions;
  }
}

class _EmptyThenSuccessProductLookupService implements ProductLookupService {
  int searchAttempts = 0;

  @override
  Future<MealAnalysisResult> lookupBarcode(String barcode) async =>
      _FakeProductLookupService.salamiPizza;

  @override
  Future<List<ProductSearchResult>> searchProducts(String query) async {
    searchAttempts++;
    if (searchAttempts <= 2) {
      return const <ProductSearchResult>[];
    }
    return _FakeProductLookupService.productSuggestions;
  }
}

import 'dart:convert';
import 'dart:io';

import '../models/meal_analysis_request.dart';
import '../models/meal_analysis_result.dart';

abstract class MealAnalyzer {
  Future<MealAnalysisResult> analyze(MealAnalysisRequest request);
}

class EdgeFunctionMealAnalyzer implements MealAnalyzer {
  const EdgeFunctionMealAnalyzer();

  static const String _supabaseUrl = 'https://ftoozzvmduptrvrrrshb.supabase.co';
  static const String _supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ0b296enZtZHVwdHJ2cnJyc2hiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc4NDEyOTAsImV4cCI6MjA5MzQxNzI5MH0.5kx8LowjRc8q8uWqJmUGU8ZjCnplSRDC1NGhm-oG7to';
  static const String _functionPath = '/functions/v1/analyze-meal';

  static const String _basePrompt = '''
ShiftFit Foto-Kalorienanalyse. Du bist ein präziser Ernährungsschätzer.

Vorgehen:
1. Identifiziere ALLE sichtbaren Lebensmittel einzeln (auch Beilagen, Saucen, Öl).
2. Schätze für jedes Lebensmittel das tatsächliche GEWICHT in Gramm anhand visueller
   Größenmerkmale: Tellergröße (Standard 27 cm), Besteck (Gabel ≈ 20 cm), Hände,
   Verpackung, Standardobjekte im Hintergrund.
3. Gib pro Item separat: name, grams, kcalPer100G (typischer Wert für DIESE Variante),
   caloriesKcal (= grams * kcalPer100G / 100).
4. Summiere zur Gesamtportion.

WICHTIG — keine Default-Antworten:
- Ein kleiner Apfel ≈ 120 g (~62 kcal), mittel ≈ 180 g (~94 kcal), groß ≈ 250 g (~130 kcal).
  Schau aktiv hin: ist der Apfel klein, normal oder groß? Antworte UNTERSCHIEDLICH je nach Foto.
- Pasta-Portionen variieren stark: 80 g trocken / 200 g gekocht für eine Person ist Standard,
  aber ein voller Teller hat oft 300-400 g gekocht.
- Bei Fleisch: Steak 150-250 g typisch, Hähnchenbrust 120-180 g pro Stück.
- Wenn das Foto klare Größen zeigt (z. B. Schale fast voll vs. nur Boden), berücksichtige das.

Falls keinerlei Größenanhaltspunkte erkennbar sind, gib confidence "low" und
einen konservativen Mittelwert mit klarem Hinweis in explanation.

Ausgabe (JSON):
{
  "mealName": "kurzer Name",
  "caloriesKcal": int,
  "estimatedGrams": int (Summe),
  "kcalPer100G": double,
  "proteinG": int|null,
  "carbsG": int|null,
  "fatG": int|null,
  "confidence": "high"|"medium"|"low",
  "explanation": "1-2 Sätze mit GRÖSSEN-BEGRÜNDUNG (warum diese Gramm, woran erkannt)",
  "items": [
    { "name": "...", "grams": int, "caloriesKcal": int, "kcalPer100G": double }
  ]
}
''';

  @override
  Future<MealAnalysisResult> analyze(MealAnalysisRequest request) async {
    final imageBytes = request.imageBytes;
    if (imageBytes == null || imageBytes.isEmpty) {
      throw const FormatException('No image bytes available for analysis.');
    }

    final note = _buildNote(request);

    final client = HttpClient();
    try {
      final uri = Uri.parse('$_supabaseUrl$_functionPath');
      final httpRequest = await client.postUrl(uri);
      httpRequest.headers.contentType = ContentType.json;
      httpRequest.headers.set('apikey', _supabaseAnonKey);
      httpRequest.headers.set('Authorization', 'Bearer $_supabaseAnonKey');
      httpRequest.write(
        jsonEncode({
          'imageBase64': base64Encode(imageBytes),
          'note': note,
        }),
      );

      final response = await httpRequest.close();
      final responseBody = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('Meal analysis failed: $responseBody');
      }

      final result = decoded['result'];
      if (result is! Map<String, dynamic>) {
        throw const FormatException('Unexpected analysis response.');
      }

      return MealAnalysisResult.fromEdgeFunction(result);
    } finally {
      client.close(force: true);
    }
  }

  String _buildNote(MealAnalysisRequest request) {
    final hint = request.portionHint;
    final freeText = request.freeTextHint;
    final extras = <String>[];
    if (hint != null && hint != MealPortionHint.normal) {
      extras.add('Nutzer-Hinweis Portionsgröße: ${hint.label} (${hint.guidance}).');
    }
    if (freeText != null && freeText.trim().isNotEmpty) {
      extras.add('Zusätzlicher Hinweis: ${freeText.trim()}');
    }
    if (extras.isEmpty) {
      return _basePrompt;
    }
    return '$_basePrompt\n\nNutzer-Kontext:\n${extras.join('\n')}';
  }
}

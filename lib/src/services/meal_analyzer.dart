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

STRENGE ITEMIZATION — ABSOLUT PFLICHT:
- Jedes sichtbar getrennte Lebensmittel ist ein EIGENER Eintrag in items[].
- Steak + Kartoffeln + Brokkoli = drei items, NIEMALS ein gemeinsamer "Teller".
- Auch Beilagen, Saucen, Dressings, sichtbares Öl/Butter werden eigene items.
- Wenn mehrere Stücke desselben Lebensmittels sichtbar sind (z. B. 3 Kartoffeln),
  fasse sie in EINEM Item mit Gesamtgramm zusammen ("Kartoffeln", grams = Summe).
- Brot/Burger-Brötchen + Belag/Patty = jeweils eigene items.
- "mealName" ist der Sammelname (z. B. "Teller mit Steak, Kartoffeln, Brokkoli");
  "items[]" ist die strikte Einzelauflistung.

GRÖSSEN-LOGIK:
- Schätze pro Item das tatsächliche GEWICHT in Gramm anhand visueller Anhaltspunkte:
  Teller (Standard 27 cm), Besteck (Gabel ≈ 20 cm), Hände, Verpackung.
- Antworte UNTERSCHIEDLICH je nach Foto. Niemals Default-Werte für eine
  Lebensmittelkategorie wiederholen.

REFERENZ-RANGES (nur als Korridore — exakter Wert kommt aus dem Foto):
- Apfel: klein ≈ 120 g (~62 kcal), mittel ≈ 180 g (~94 kcal), groß ≈ 250 g (~130 kcal).
- Banane: klein ≈ 80 g, mittel ≈ 120 g, groß ≈ 180 g.
- Pasta gekocht: 200 g pro Person Standard, voller Teller 300-400 g.
- Reis gekocht: 150-250 g pro Portion.
- Steak: 150-250 g typisch, ein dickes Stück bis 350 g.
- Hähnchenbrust: 120-180 g pro Stück.
- Kartoffeln gekocht: 150-250 g pro Portion.
- Brokkoli/Gemüse: 80-150 g pro Portion.
- Scheibe Brot: 30-50 g.

JEDES ITEM enthält:
- name: konkret, deutsch wenn möglich ("Steak", "Kartoffeln", nicht "meat", "carbs")
- grams: int, aus dem Foto geschätzt
- kcalPer100G: typischer Wert für DIESE Variante (z. B. Steak medium ~220, Kartoffeln
  gekocht ~80, Brokkoli ~35)
- caloriesKcal: int, = grams * kcalPer100G / 100 (rechne korrekt nach)

Falls keinerlei Größenanhaltspunkte erkennbar sind, gib confidence "low" und
einen konservativen Mittelwert mit klarem Hinweis in explanation.

Ausgabe (strikt JSON, kein Fließtext daneben):
{
  "mealName": "Sammelname der Mahlzeit",
  "caloriesKcal": int (Summe aller items),
  "estimatedGrams": int (Summe aller items),
  "kcalPer100G": double (Gesamtmittelwert),
  "proteinG": int|null,
  "carbsG": int|null,
  "fatG": int|null,
  "confidence": "high"|"medium"|"low",
  "explanation": "1-2 Sätze mit Größen-Begründung (woran erkannt)",
  "items": [
    { "name": "...", "grams": int, "caloriesKcal": int, "kcalPer100G": double },
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

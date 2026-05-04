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
  static const String _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ0b296enZtZHVwdHJ2cnJyc2hiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc4NDEyOTAsImV4cCI6MjA5MzQxNzI5MH0.5kx8LowjRc8q8uWqJmUGU8ZjCnplSRDC1NGhm-oG7to';
  static const String _functionPath = '/functions/v1/analyze-meal';

  @override
  Future<MealAnalysisResult> analyze(MealAnalysisRequest request) async {
    final imageBytes = request.imageBytes;
    if (imageBytes == null || imageBytes.isEmpty) {
      throw const FormatException('No image bytes available for analysis.');
    }

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
          'note':
              'ShiftFit iOS Analyse. Bitte wenn möglich mealName, caloriesKcal, estimatedGrams, kcalPer100G, proteinG, carbsG, fatG, confidence und explanation als JSON zurückgeben. Keine exakte Vermessung behaupten; Portionsgröße als Schätzung markieren.',
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
}

class DemoMealAnalyzer implements MealAnalyzer {
  const DemoMealAnalyzer();

  @override
  Future<MealAnalysisResult> analyze(MealAnalysisRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final index = request.imageId.codeUnits.fold<int>(
          0,
          (previous, value) => previous + value,
        ) %
        _templates.length;
    return _templates[index];
  }

  static const List<MealAnalysisResult> _templates = [
    MealAnalysisResult(
      mealName: 'Bowl mit Huhn und Reis',
      caloriesKcal: 690,
      estimatedGrams: 480,
      kcalPer100G: 144,
      protein: '38-48 g',
      carbs: '68-86 g',
      fat: '18-28 g',
      confidence: '72%',
      portionNotes:
          'Wirkt wie eine mittlere Bowl mit einer Handfläche Protein und etwa 1,5 Tassen Reis.',
    ),
    MealAnalysisResult(
      mealName: 'Pasta mit Tomatensauce',
      caloriesKcal: 615,
      estimatedGrams: 420,
      kcalPer100G: 146,
      protein: '18-28 g',
      carbs: '82-104 g',
      fat: '12-22 g',
      confidence: '68%',
      portionNotes:
          'Portion und Ölmenge sind visuell schwer zu trennen; Käse oder Öl kann die Spanne erhöhen.',
    ),
    MealAnalysisResult(
      mealName: 'Frühstücksteller',
      caloriesKcal: 510,
      estimatedGrams: 360,
      kcalPer100G: 142,
      protein: '20-32 g',
      carbs: '36-58 g',
      fat: '18-30 g',
      confidence: '70%',
      portionNotes:
          'Schätzung passt zu Eiern, Brot und etwas Fettquelle; Getränke sind nicht eingerechnet.',
    ),
  ];
}

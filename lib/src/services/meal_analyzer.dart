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
              'ShiftFit iOS Analyse. Antworte wenn moeglich als strukturiertes JSON mit mealName, caloriesKcal, estimatedGrams, kcalPer100G, proteinG, carbsG, fatG, confidence, explanation und einem items-Array. Jedes Item sollte name, grams, caloriesKcal und wenn moeglich kcalPer100G enthalten. Wenn mehrere Lebensmittel sichtbar sind, bitte die Mahlzeit itemisiert zerlegen und Gramm pro Item schaetzen. Keine exakte Vermessung behaupten; Unsicherheit klar als Schaetzung markieren.',
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

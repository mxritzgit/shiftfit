import 'dart:convert';
import 'dart:io';

import '../models/meal_analysis_result.dart';

class OpenFoodFactsProductService {
  const OpenFoodFactsProductService();

  static const String _baseUrl = 'https://world.openfoodfacts.org/api/v2/product';
  static const String _fields = 'code,product_name,brands,quantity,serving_size,'
      'serving_quantity,nutriments,image_front_small_url';

  Future<MealAnalysisResult> lookupBarcode(String barcode) async {
    final cleanBarcode = barcode.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanBarcode.isEmpty) {
      throw const FormatException('Empty barcode.');
    }

    final client = HttpClient();
    try {
      final uri = Uri.parse('$_baseUrl/$cleanBarcode.json?fields=$_fields');
      final request = await client.getUrl(uri);
      request.headers.set(
        HttpHeaders.userAgentHeader,
        'ShiftFit/1.0 (OpenFoodFacts barcode nutrition lookup)',
      );
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('OpenFoodFacts lookup failed: $body');
      }

      final decoded = jsonDecode(body) as Map<String, dynamic>;
      if (decoded['status'] != 1 || decoded['product'] is! Map<String, dynamic>) {
        throw const FormatException('Product not found in OpenFoodFacts.');
      }

      return MealAnalysisResult.fromOpenFoodFacts(
        decoded['product'] as Map<String, dynamic>,
        cleanBarcode,
      );
    } finally {
      client.close(force: true);
    }
  }
}

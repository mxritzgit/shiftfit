import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/meal_analysis_result.dart';

abstract class ProductLookupService {
  Future<MealAnalysisResult> lookupBarcode(String barcode);
  Future<List<ProductSearchResult>> searchProducts(String query);
}

class ProductSearchResult {
  const ProductSearchResult({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.kcalPer100G,
    required this.result,
    this.imageUrl,
  });

  final String code;
  final String title;
  final String subtitle;
  final double kcalPer100G;
  final MealAnalysisResult result;
  final String? imageUrl;

  factory ProductSearchResult.fromOpenFoodFacts(Map<String, dynamic> product) {
    final code = product['code']?.toString().trim() ?? '';
    final result = MealAnalysisResult.fromOpenFoodFacts(product, code);
    final brand = result.brand?.trim();
    final quantity = _firstNonEmptyString(product, const ['quantity']);
    final imageUrl = _firstNonEmptyString(product, const [
      'image_front_small_url',
      'image_front_url',
      'image_small_url',
      'image_url',
    ]);
    final subtitleParts = <String>[
      if (brand != null && brand.isNotEmpty) brand,
      if (quantity != null && quantity.isNotEmpty) quantity,
      result.kcalPer100Label,
    ];

    return ProductSearchResult(
      code: code,
      title: result.mealName,
      subtitle: subtitleParts.join(' · '),
      kcalPer100G: result.kcalPer100G,
      result: result,
      imageUrl: imageUrl,
    );
  }
}

class OpenFoodFactsProductService implements ProductLookupService {
  const OpenFoodFactsProductService();

  static const String _productBaseUrl = 'https://world.openfoodfacts.org/api/v2/product';
  static const List<String> _searchBaseUrls = <String>[
    'https://de.openfoodfacts.org/cgi/search.pl',
    'https://world.openfoodfacts.org/cgi/search.pl',
  ];
  static const String _fields = 'code,product_name,generic_name,brands,quantity,serving_size,'
      'serving_quantity,nutriments,image_front_small_url,image_front_url,'
      'image_small_url,image_url';

  @override
  Future<MealAnalysisResult> lookupBarcode(String barcode) async {
    final cleanBarcode = barcode.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanBarcode.isEmpty) {
      throw const FormatException('Empty barcode.');
    }

    final client = HttpClient();
    try {
      final uri = Uri.parse('$_productBaseUrl/$cleanBarcode.json?fields=$_fields');
      final request = await client.getUrl(uri);
      _setUserAgent(request);
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

  @override
  Future<List<ProductSearchResult>> searchProducts(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.length < 2) {
      return const <ProductSearchResult>[];
    }

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      Object? lastError;

      for (final baseUrl in _searchBaseUrls) {
        try {
          final results = await _searchProductsFromEndpoint(
            client: client,
            baseUrl: baseUrl,
            query: cleanQuery,
          );
          if (results.isNotEmpty) {
            return results;
          }
        } catch (error) {
          lastError = error;
        }
      }

      if (lastError != null) {
        throw lastError;
      }

      return const <ProductSearchResult>[];
    } finally {
      client.close(force: true);
    }
  }

  static Future<List<ProductSearchResult>> _searchProductsFromEndpoint({
    required HttpClient client,
    required String baseUrl,
    required String query,
  }) async {
    final uri = Uri.parse(baseUrl).replace(
      queryParameters: <String, String>{
        'search_terms': query,
        'search_simple': '1',
        'action': 'process',
        'json': '1',
        'page_size': '12',
        'fields': _fields,
      },
    );
    final request = await client.getUrl(uri).timeout(const Duration(seconds: 8));
    _setUserAgent(request);
    final response = await request.close().timeout(const Duration(seconds: 12));
    final body = await response.transform(utf8.decoder).join().timeout(
      const Duration(seconds: 12),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('OpenFoodFacts search failed: ${response.statusCode}');
    }

    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final products = decoded['products'];
    if (products is! List) {
      return const <ProductSearchResult>[];
    }

    return products
        .whereType<Map>()
        .map(
          (product) => ProductSearchResult.fromOpenFoodFacts(
            product.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .where((product) => product.title.trim().isNotEmpty)
        .toList(growable: false);
  }

  static void _setUserAgent(HttpClientRequest request) {
    request.headers.set(
      HttpHeaders.userAgentHeader,
      'ShiftFit/1.0 (OpenFoodFacts nutrition lookup; mxritzgit/shiftfit)',
    );
  }
}

String? _firstNonEmptyString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) {
      continue;
    }
    final text = value.toString().trim();
    if (text.isNotEmpty) {
      return text;
    }
  }
  return null;
}

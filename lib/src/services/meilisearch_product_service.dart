import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../config/search_config.dart';
import '../models/meal_analysis_result.dart';
import 'open_food_facts_product_service.dart';

/// Product lookup backed by our self-hosted EU mirror (Meilisearch behind a
/// Cloud Run HTTPS proxy). The proxy returns documents in the same field shape
/// as OpenFoodFacts, so the existing `fromOpenFoodFacts` factories are reused.
class MeilisearchProductService implements ProductLookupService {
  MeilisearchProductService({String? baseUrl})
      : baseUrl = (baseUrl ?? SearchConfig.proxyBaseUrl)
            .replaceAll(RegExp(r'/+$'), '');

  final String baseUrl;

  static const Duration _connectTimeout = Duration(seconds: 6);
  static const Duration _readTimeout = Duration(seconds: 8);

  @override
  Future<List<ProductSearchResult>> searchProducts(String query) async {
    final q = query.trim();
    if (q.length < 2) {
      return const <ProductSearchResult>[];
    }
    final client = HttpClient()..connectionTimeout = _connectTimeout;
    try {
      final uri = Uri.parse('$baseUrl/search')
          .replace(queryParameters: <String, String>{'q': q, 'limit': '12'});
      final request = await client.getUrl(uri).timeout(_connectTimeout);
      final response = await request.close().timeout(_readTimeout);
      final body =
          await response.transform(utf8.decoder).join().timeout(_readTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('Mirror search failed: ${response.statusCode}');
      }

      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final hits = decoded['hits'];
      if (hits is! List) {
        return const <ProductSearchResult>[];
      }
      return hits
          .whereType<Map>()
          .map(
            (hit) => ProductSearchResult.fromOpenFoodFacts(
              hit.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .where((product) => product.title.trim().isNotEmpty)
          .toList(growable: false);
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<MealAnalysisResult> lookupBarcode(String barcode) async {
    final clean = barcode.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) {
      throw const FormatException('Empty barcode.');
    }
    final client = HttpClient()..connectionTimeout = _connectTimeout;
    try {
      final uri = Uri.parse('$baseUrl/barcode/$clean');
      final request = await client.getUrl(uri).timeout(_connectTimeout);
      final response = await request.close().timeout(_readTimeout);
      final body =
          await response.transform(utf8.decoder).join().timeout(_readTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('Mirror barcode failed: ${response.statusCode}');
      }

      final decoded = jsonDecode(body) as Map<String, dynamic>;
      if (decoded['found'] != true || decoded['product'] is! Map) {
        throw const FormatException('Product not found in mirror.');
      }
      final product = (decoded['product'] as Map)
          .map((key, value) => MapEntry(key.toString(), value));
      return MealAnalysisResult.fromOpenFoodFacts(product, clean);
    } finally {
      client.close(force: true);
    }
  }
}

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/meal_component.dart';
import '../models/meal_analysis_request.dart';
import '../models/meal_analysis_result.dart';
import '../services/meal_analyzer.dart';
import '../services/meal_photo_input.dart';
import '../services/open_food_facts_product_service.dart';
import '../theme/app_colors.dart';
import '../widgets/common/basic_widgets.dart';
import '../widgets/meal/meal_widgets.dart';
import 'barcode_scanner_screen.dart';

class MealAnalysisScreen extends StatefulWidget {
  MealAnalysisScreen({
    super.key,
    MealAnalyzer? analyzer,
    ProductLookupService? productService,
    MealPhotoInput? photoInput,
    required this.dailyConsumedKcal,
    required this.onAddToDailyTotal,
  }) : analyzer = analyzer ?? const EdgeFunctionMealAnalyzer(),
       productService = productService ?? const OpenFoodFactsProductService(),
       photoInput = photoInput ?? DeviceMealPhotoInput();

  final MealAnalyzer analyzer;
  final ProductLookupService productService;
  final MealPhotoInput photoInput;
  final int dailyConsumedKcal;
  final ValueChanged<int> onAddToDailyTotal;

  @override
  State<MealAnalysisScreen> createState() => _MealAnalysisScreenState();
}

class _MealAnalysisScreenState extends State<MealAnalysisScreen> {
  Uint8List? selectedImageBytes;
  MealAnalysisResult? result;
  bool isLoading = false;
  bool mealConfirmed = false;
  bool addedToDailyTotal = false;
  int? addedCaloriesSnapshot;
  final TextEditingController searchController = TextEditingController();
  Timer? productSearchDebounce;
  int productSearchRequestId = 0;
  final Map<String, List<ProductSearchResult>> productSearchCache =
      <String, List<ProductSearchResult>>{};
  List<ProductSearchResult> productSuggestions = const <ProductSearchResult>[];
  bool isSearchingProducts = false;
  String? productSearchMessage;
  static const Duration _productSearchDebounceDelay = Duration(milliseconds: 1000);
  static const Duration _productSearchRetryDelay = Duration(milliseconds: 1500);
  static const int _productSearchMaxAttempts = 6;

  @override
  void dispose() {
    productSearchDebounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  Future<void> scanBarcode() async {
    final barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (barcode == null || barcode.trim().isEmpty || !mounted) {
      return;
    }

    await lookupBarcode(barcode.trim());
  }

  Future<void> lookupBarcode(String barcode) async {
    setState(() {
      selectedImageBytes = null;
      result = null;
      isLoading = true;
      mealConfirmed = false;
      addedToDailyTotal = false;
      addedCaloriesSnapshot = null;
    });

    try {
      final lookupResult = await widget.productService.lookupBarcode(barcode);
      if (!mounted) {
        return;
      }

      setState(() {
        result = lookupResult;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Barcode $barcode nicht gefunden oder OpenFoodFacts ist nicht erreichbar.',
          ),
        ),
      );
    }
  }

  void scheduleProductSearch(String value) {
    final query = value.trim();
    productSearchDebounce?.cancel();

    if (query.length < 2) {
      productSearchRequestId++;
      setState(() {
        isSearchingProducts = false;
        productSuggestions = const <ProductSearchResult>[];
        productSearchMessage = null;
      });
      return;
    }

    productSearchDebounce = Timer(
      _productSearchDebounceDelay,
      () => searchProducts(queryOverride: query, showTransientError: false),
    );
  }

  Future<void> searchProducts({
    String? queryOverride,
    bool showTransientError = true,
  }) async {
    productSearchDebounce?.cancel();
    final query = (queryOverride ?? searchController.text).trim();
    if (query.length < 2) {
      setState(() {
        productSuggestions = const <ProductSearchResult>[];
        productSearchMessage = 'Gib mindestens 2 Zeichen ein, z.B. Dr Oetker Salami.';
      });
      return;
    }

    final cacheKey = normalizeProductSearchQuery(query);
    final cachedSuggestions = productSearchCache[cacheKey];
    if (cachedSuggestions != null) {
      productSearchRequestId++;
      setState(() {
        productSuggestions = cachedSuggestions;
        isSearchingProducts = false;
        productSearchMessage = cachedSuggestions.isEmpty
            ? 'Keine passenden Produkte gefunden. Versuche Marke + Produktname.'
            : null;
      });
      return;
    }

    final requestId = ++productSearchRequestId;

    setState(() {
      isSearchingProducts = true;
      productSearchMessage = null;
    });

    try {
      final suggestions = await searchProductsWithRetry(query, requestId);
      if (!mounted) {
        return;
      }

      if (requestId != productSearchRequestId ||
          query != searchController.text.trim()) {
        return;
      }

      setState(() {
        productSuggestions = suggestions;
        isSearchingProducts = false;
        productSearchMessage = suggestions.isEmpty
            ? 'Keine passenden Produkte gefunden. Versuche Marke + Produktname.'
            : null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      if (requestId != productSearchRequestId ||
          query != searchController.text.trim()) {
        return;
      }

      setState(() {
        isSearchingProducts = false;
        productSearchMessage = showTransientError
            ? 'OpenFoodFacts-Suche gerade nicht erreichbar.'
            : null;
      });
    }
  }

  Future<List<ProductSearchResult>> searchProductsWithRetry(
    String query,
    int requestId,
  ) async {
    Object? lastError;
    List<ProductSearchResult> lastSuggestions = const <ProductSearchResult>[];

    for (var attempt = 0; attempt < _productSearchMaxAttempts; attempt++) {
      try {
        final suggestions = await widget.productService.searchProducts(query);
        lastError = null;
        if (suggestions.isNotEmpty) {
          productSearchCache[normalizeProductSearchQuery(query)] = suggestions;
          return suggestions;
        }
        lastSuggestions = suggestions;
      } catch (error) {
        lastError = error;
      }

      if (attempt == _productSearchMaxAttempts - 1 ||
          requestId != productSearchRequestId) {
        break;
      }

      await Future<void>.delayed(_productSearchRetryDelay);
    }

    if (lastError == null) {
      return lastSuggestions;
    }

    throw lastError;
  }

  static String normalizeProductSearchQuery(String query) {
    return query.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  void selectProduct(ProductSearchResult product) {
    setState(() {
      selectedImageBytes = null;
      result = product.result;
      mealConfirmed = false;
      addedToDailyTotal = false;
      addedCaloriesSnapshot = null;
      productSearchMessage =
          '${product.title} ausgewählt. Gramm prüfen und zu heute hinzufügen.';
    });
  }

  Future<void> pickAndAnalyze(ImageSource source) async {
    MealPhotoSelection? selection;
    try {
      selection = await widget.photoInput.pick(source);
    } on PlatformException catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            source == ImageSource.camera
                ? 'Kamera konnte nicht geöffnet werden. Prüfe die Berechtigung.'
                : 'Galerie konnte nicht geöffnet werden. Prüfe die Berechtigung.',
          ),
        ),
      );
      return;
    }

    if (selection == null) {
      return;
    }

    await runAnalysis(selection.request, selection.previewBytes);
  }

  Future<void> runAnalysis(
    MealAnalysisRequest request,
    Uint8List? imageBytes,
  ) async {
    setState(() {
      selectedImageBytes = imageBytes;
      result = null;
      isLoading = true;
      mealConfirmed = false;
      addedToDailyTotal = false;
      addedCaloriesSnapshot = null;
    });

    try {
      final analysisResult = await widget.analyzer.analyze(request);
      if (!mounted) {
        return;
      }

      setState(() {
        result = analysisResult;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Analyse fehlgeschlagen. Prüfe Internet, Supabase und OpenRouter.',
          ),
        ),
      );
    }
  }

  void confirmMealEstimate() {
    setState(() => mealConfirmed = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kalorienschätzung bestätigt.')),
    );
  }

  void addCurrentResultToDailyTotal() {
    final currentResult = result;
    if (currentResult == null || addedToDailyTotal) {
      return;
    }

    widget.onAddToDailyTotal(currentResult.caloriesKcal);
    setState(() {
      addedToDailyTotal = true;
      addedCaloriesSnapshot = currentResult.caloriesKcal;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${currentResult.caloriesKcal} kcal zu heute hinzugefügt.'),
      ),
    );
  }

  Future<void> adjustMealPortion() async {
    final currentResult = result;
    if (currentResult == null) {
      return;
    }

    final adjustment = await showWeightAdjustmentSheet(context, currentResult);
    if (!mounted || adjustment == null) {
      return;
    }

    MealAnalysisResult? updatedResult;

    if (adjustment is int && adjustment > 0) {
      updatedResult = currentResult.adjustedToGrams(adjustment);
    } else if (adjustment is List<MealComponent>) {
      updatedResult = currentResult.adjustedToItems(adjustment);
    }

    if (updatedResult == null) {
      return;
    }

    final wasAdded = addedToDailyTotal;
    final previousAddedCalories = addedCaloriesSnapshot;

    setState(() {
      result = updatedResult;
      mealConfirmed = true;
      if (wasAdded) {
        addedToDailyTotal = true;
        addedCaloriesSnapshot = updatedResult!.caloriesKcal;
      } else {
        addedToDailyTotal = false;
        addedCaloriesSnapshot = null;
      }
    });

    if (wasAdded && previousAddedCalories != null) {
      final delta = updatedResult.caloriesKcal - previousAddedCalories;
      if (delta != 0) {
        widget.onAddToDailyTotal(delta);
      }
    }

    if (adjustment is int && adjustment > 0) {
      final message = wasAdded
          ? 'Portion auf $adjustment g angepasst. Tageswert aktualisiert.'
          : 'Portion auf $adjustment g angepasst.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } else if (adjustment is List<MealComponent>) {
      final message = wasAdded
          ? 'Bestandteile und Tageswert aktualisiert.'
          : 'Bestandteile und Gramm angepasst.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Widget buildProductSearchCard() {
    return AppCard(
      key: const ValueKey('kcal-product-search-card'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Produktsuche', action: 'OpenFoodFacts'),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('kcal-product-search-input'),
            controller: searchController,
            textInputAction: TextInputAction.search,
            onChanged: scheduleProductSearch,
            onSubmitted: (_) => searchProducts(),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: 'z.B. Dr Oetker Salami',
              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: textMuted),
              suffixIcon: IconButton(
                key: const ValueKey('kcal-product-search-button'),
                onPressed: isSearchingProducts ? null : searchProducts,
                icon: isSearchingProducts
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_forward_rounded, size: 18),
              ),
            ),
          ),
          if (productSearchMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              productSearchMessage!,
              key: const ValueKey('kcal-product-search-message'),
              style: const TextStyle(
                color: textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ],
          if (productSuggestions.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (var index = 0; index < productSuggestions.length; index++) ...[
              ProductSuggestionTile(
                key: ValueKey('kcal-product-suggestion-$index'),
                product: productSuggestions[index],
                onTap: () => selectProduct(productSuggestions[index]),
              ),
              if (index != productSuggestions.length - 1)
                const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }

  Widget buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: KcalActionButton(
            key: const ValueKey('analyse-camera-button'),
            icon: Icons.photo_camera_rounded,
            label: 'Kamera',
            color: orange,
            filled: true,
            onPressed: isLoading ? null : () => pickAndAnalyze(ImageSource.camera),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: KcalActionButton(
            key: const ValueKey('analyse-gallery-button'),
            icon: Icons.photo_library_outlined,
            label: 'Galerie',
            color: pink,
            onPressed: isLoading ? null : () => pickAndAnalyze(ImageSource.gallery),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: KcalActionButton(
            key: const ValueKey('analyse-barcode-button'),
            icon: Icons.qr_code_scanner_rounded,
            label: 'Barcode',
            color: cyan,
            onPressed: isLoading ? null : scanBarcode,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('screen-kcal-tracker'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KcalSummaryHeader(dailyConsumedKcal: widget.dailyConsumedKcal),
        const SizedBox(height: 14),
        buildQuickActions(),
        const SizedBox(height: 14),
        buildProductSearchCard(),
        const SizedBox(height: 14),
        if (selectedImageBytes != null) ...[
          MealPreviewCard(imageBytes: selectedImageBytes),
          const SizedBox(height: 14),
        ],
        if (isLoading)
          const MealLoadingCard()
        else if (result != null)
          MealResultCard(
            result: result!,
            confirmed: mealConfirmed,
            addedToDailyTotal: addedToDailyTotal,
            onConfirmed: confirmMealEstimate,
            onAdjustRequested: adjustMealPortion,
            onAddToDailyRequested: addCurrentResultToDailyTotal,
          )
        else
          const MealEmptyCard(),
      ],
    );
  }
}

class KcalSummaryHeader extends StatelessWidget {
  const KcalSummaryHeader({
    super.key,
    required this.dailyConsumedKcal,
  });

  final int dailyConsumedKcal;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('analyse-daily-kcal-card'),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: hairline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StatusPill(label: 'Heute', color: lime),
                const SizedBox(height: 14),
                Text(
                  '$dailyConsumedKcal kcal',
                  key: const ValueKey('analyse-daily-kcal-total'),
                  style: const TextStyle(
                    color: textPrimary,
                    fontSize: 34,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1.2,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'getrackt',
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: lime.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: lime,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class KcalActionButton extends StatelessWidget {
  const KcalActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final foreground = filled ? bg : color;
    return Opacity(
      opacity: onPressed == null ? 0.5 : 1,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: filled ? color : surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: filled ? color : color.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: foreground, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductSuggestionTile extends StatelessWidget {
  const ProductSuggestionTile({
    super.key,
    required this.product,
    required this.onTap,
  });

  final ProductSearchResult product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: surfaceSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: product.imageUrl == null
                  ? const Icon(
                      Icons.fastfood_outlined,
                      color: textMuted,
                      size: 20,
                    )
                  : Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.fastfood_outlined,
                        color: textMuted,
                        size: 20,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.add_circle_outline_rounded, color: lime, size: 20),
          ],
        ),
      ),
    );
  }
}

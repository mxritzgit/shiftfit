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
  List<ProductSearchResult> productSuggestions = const <ProductSearchResult>[];
  bool isSearchingProducts = false;
  String? productSearchMessage;

  @override
  void dispose() {
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

  Future<void> searchProducts() async {
    final query = searchController.text.trim();
    if (query.length < 2) {
      setState(() {
        productSuggestions = const <ProductSearchResult>[];
        productSearchMessage = 'Gib mindestens 2 Zeichen ein, z.B. Dr Oetker Salami.';
      });
      return;
    }

    setState(() {
      isSearchingProducts = true;
      productSearchMessage = null;
      productSuggestions = const <ProductSearchResult>[];
    });

    try {
      final suggestions = await widget.productService.searchProducts(query);
      if (!mounted) {
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

      setState(() {
        isSearchingProducts = false;
        productSearchMessage = 'OpenFoodFacts-Suche gerade nicht erreichbar.';
      });
    }
  }

  void selectProduct(ProductSearchResult product) {
    setState(() {
      selectedImageBytes = null;
      result = product.result;
      mealConfirmed = false;
      addedToDailyTotal = false;
      addedCaloriesSnapshot = null;
      productSearchMessage = '${product.title} ausgewählt. Prüfe die Gramm und füge es dann zu heute hinzu.';
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
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Produktsuche', action: 'OpenFoodFacts'),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('kcal-product-search-input'),
            controller: searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => searchProducts(),
            style: const TextStyle(fontWeight: FontWeight.w800),
            decoration: InputDecoration(
              hintText: 'z.B. Dr Oetker Salami',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                key: const ValueKey('kcal-product-search-button'),
                onPressed: isSearchingProducts ? null : searchProducts,
                icon: isSearchingProducts
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_forward_rounded),
              ),
            ),
          ),
          if (productSearchMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              productSearchMessage!,
              key: const ValueKey('kcal-product-search-message'),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.64),
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ],
          if (productSuggestions.isNotEmpty) ...[
            const SizedBox(height: 14),
            for (var index = 0; index < productSuggestions.length; index++) ...[
              ProductSuggestionTile(
                key: ValueKey('kcal-product-suggestion-$index'),
                product: productSuggestions[index],
                onTap: () => selectProduct(productSuggestions[index]),
              ),
              if (index != productSuggestions.length - 1) const SizedBox(height: 10),
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
        const SizedBox(width: 10),
        Expanded(
          child: KcalActionButton(
            key: const ValueKey('analyse-gallery-button'),
            icon: Icons.photo_library_rounded,
            label: 'Galerie',
            color: pink,
            onPressed: isLoading ? null : () => pickAndAnalyze(ImageSource.gallery),
          ),
        ),
        const SizedBox(width: 10),
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
        const SizedBox(height: 18),
        if (selectedImageBytes != null) ...[
          MealPreviewCard(imageBytes: selectedImageBytes),
          const SizedBox(height: 18),
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            lime.withValues(alpha: 0.92),
            cyan.withValues(alpha: 0.72),
            Colors.white.withValues(alpha: 0.10),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: lime.withValues(alpha: 0.18),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: bg.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'HEUTE',
                    style: TextStyle(
                      color: bg,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '$dailyConsumedKcal kcal',
                  key: const ValueKey('analyse-daily-kcal-total'),
                  style: const TextStyle(
                    color: bg,
                    fontSize: 46,
                    height: 0.92,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -2.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'getrackt',
                  style: TextStyle(
                    color: bg.withValues(alpha: 0.72),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: bg.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.local_fire_department_rounded, color: bg, size: 40),
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
    final foreground = filled ? bg : Colors.white;
    return Opacity(
      opacity: onPressed == null ? 0.46 : 1,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 86,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: filled ? color : color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: filled ? 0.72 : 0.34)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: foreground, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(16),
              ),
              child: product.imageUrl == null
                  ? Icon(
                      Icons.fastfood_rounded,
                      color: Colors.white.withValues(alpha: 0.38),
                    )
                  : Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.fastfood_rounded,
                        color: Colors.white.withValues(alpha: 0.38),
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
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.58),
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.add_circle_rounded, color: lime),
          ],
        ),
      ),
    );
  }
}

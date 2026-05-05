import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/meal_component.dart';
import '../models/meal_analysis_request.dart';
import '../models/meal_analysis_result.dart';
import '../models/shift_fit_plan.dart';
import '../services/meal_analyzer.dart';
import '../services/meal_photo_input.dart';
import '../services/open_food_facts_product_service.dart';
import '../theme/app_colors.dart';
import '../widgets/common/basic_widgets.dart';
import '../widgets/meal/meal_widgets.dart';
import '../widgets/shared/shiftfit_top_bar.dart';
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

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('screen-kcal-tracker'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ShiftFitTopBar(
          plan: ShiftFitPlan(
            recommendation: 'Kcal Tracker',
            focus: 'Suchen, scannen, Foto-KI',
            tagline: 'Produkte finden, Portion anpassen und sauber zu heute hinzufügen.',
            totalMinutes: 0,
            intensity: 'Live',
            recoveryScore: 78,
            accent: lime,
            sleepHint: '',
            fuelHint: '',
            breathHint: '',
            blocks: [],
          ),
        ),
        const SizedBox(height: 24),
        AppCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StatusPill(label: 'Kcal Tracker', color: lime),
              const SizedBox(height: 18),
              const Text(
                'Kalorien\ntracken',
                key: ValueKey('kcal-tracker-hero-title'),
                style: TextStyle(
                  fontSize: 40,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Suche Produkte über OpenFoodFacts, scanne einen Barcode oder nutze Foto-KI für lose Mahlzeiten. Wenn mehrere Lebensmittel erkannt werden, kannst du jedes einzeln in Gramm anpassen.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.64),
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      key: const ValueKey('analyse-camera-button'),
                      onPressed: isLoading
                          ? null
                          : () => pickAndAnalyze(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_rounded),
                      label: const Text('Kamera'),
                      style: FilledButton.styleFrom(
                        backgroundColor: orange,
                        foregroundColor: bg,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const ValueKey('analyse-gallery-button'),
                      onPressed: isLoading
                          ? null
                          : () => pickAndAnalyze(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_rounded),
                      label: const Text('Galerie'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: orange.withValues(alpha: 0.45)),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const ValueKey('analyse-barcode-button'),
                  onPressed: isLoading ? null : scanBarcode,
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('Barcode scannen'),
                  style: FilledButton.styleFrom(
                    backgroundColor: cyan,
                    foregroundColor: bg,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        MealDailyTotalCard(dailyConsumedKcal: widget.dailyConsumedKcal),
        const SizedBox(height: 18),
        buildProductSearchCard(),
        const SizedBox(height: 18),
        MealPreviewCard(imageBytes: selectedImageBytes),
        const SizedBox(height: 18),
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

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/favorite_meal.dart';
import '../../models/logged_meal.dart';
import '../../models/meal_analysis_request.dart';
import '../../models/meal_analysis_result.dart';
import '../../models/meal_component.dart';
import '../../screens/barcode_scanner_screen.dart';
import '../../services/meal_analyzer.dart';
import '../../services/meal_photo_input.dart';
import '../../services/open_food_facts_product_service.dart';
import '../../theme/app_colors.dart';
import '../meal/meal_widgets.dart';

Future<void> showAddMealSheet(
  BuildContext context, {
  required MealSlot slot,
  required MealAnalyzer analyzer,
  required ProductLookupService productService,
  required MealPhotoInput photoInput,
  required List<FavoriteMeal> favorites,
  required void Function(MealAnalysisResult, MealSlot) onAdd,
  required ValueChanged<int> onAdjustDailyKcal,
  required ValueChanged<String> onRemoveFavorite,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (sheetContext) {
      return AddMealSheet(
        slot: slot,
        analyzer: analyzer,
        productService: productService,
        photoInput: photoInput,
        favorites: favorites,
        onAdd: onAdd,
        onAdjustDailyKcal: onAdjustDailyKcal,
        onRemoveFavorite: onRemoveFavorite,
      );
    },
  );
}

class AddMealSheet extends StatefulWidget {
  const AddMealSheet({
    super.key,
    required this.slot,
    required this.analyzer,
    required this.productService,
    required this.photoInput,
    required this.favorites,
    required this.onAdd,
    required this.onAdjustDailyKcal,
    required this.onRemoveFavorite,
  });

  final MealSlot slot;
  final MealAnalyzer analyzer;
  final ProductLookupService productService;
  final MealPhotoInput photoInput;
  final List<FavoriteMeal> favorites;
  final void Function(MealAnalysisResult, MealSlot) onAdd;
  final ValueChanged<int> onAdjustDailyKcal;
  final ValueChanged<String> onRemoveFavorite;

  @override
  State<AddMealSheet> createState() => _AddMealSheetState();
}

class _AddMealSheetState extends State<AddMealSheet> {
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
  static const Duration _productSearchDebounceDelay =
      Duration(milliseconds: 1000);
  static const Duration _productSearchRetryDelay =
      Duration(milliseconds: 1500);
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
      if (!mounted) return;
      setState(() {
        result = lookupResult;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Barcode $barcode nicht gefunden oder OpenFoodFacts nicht erreichbar.',
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
        productSearchMessage =
            'Gib mindestens 2 Zeichen ein, z.B. Dr Oetker Salami.';
      });
      return;
    }

    final cacheKey = _normalizeQuery(query);
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
      final suggestions = await _searchWithRetry(query, requestId);
      if (!mounted) return;
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
      if (!mounted) return;
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

  Future<List<ProductSearchResult>> _searchWithRetry(
    String query,
    int requestId,
  ) async {
    Object? lastError;
    var lastSuggestions = const <ProductSearchResult>[];

    for (var attempt = 0; attempt < _productSearchMaxAttempts; attempt++) {
      try {
        final suggestions = await widget.productService.searchProducts(query);
        lastError = null;
        if (suggestions.isNotEmpty) {
          productSearchCache[_normalizeQuery(query)] = suggestions;
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

    if (lastError == null) return lastSuggestions;
    throw lastError;
  }

  static String _normalizeQuery(String query) {
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
          '${product.title} ausgewählt. Gramm prüfen und unten hinzufügen.';
    });
  }

  Future<void> pickAndAnalyze(ImageSource source) async {
    MealPhotoSelection? selection;
    try {
      selection = await widget.photoInput.pick(source);
    } on PlatformException catch (_) {
      if (!mounted) return;
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

    if (selection == null) return;
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
      if (!mounted) return;
      setState(() {
        result = analysisResult;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false);
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
    if (currentResult == null || addedToDailyTotal) return;
    widget.onAdd(currentResult, widget.slot);
    setState(() {
      addedToDailyTotal = true;
      addedCaloriesSnapshot = currentResult.caloriesKcal;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${currentResult.caloriesKcal} kcal zu ${widget.slot.label} hinzugefügt.',
        ),
      ),
    );
  }

  void pickFavorite(MealAnalysisResult favorite) {
    setState(() {
      selectedImageBytes = null;
      result = favorite;
      mealConfirmed = false;
      addedToDailyTotal = false;
      addedCaloriesSnapshot = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${favorite.mealName} geladen.')),
    );
  }

  Future<void> adjustMealPortion() async {
    final currentResult = result;
    if (currentResult == null) return;

    final adjustment = await showWeightAdjustmentSheet(context, currentResult);
    if (!mounted || adjustment == null) return;

    MealAnalysisResult? updated;
    if (adjustment is int && adjustment > 0) {
      updated = currentResult.adjustedToGrams(adjustment);
    } else if (adjustment is List<MealComponent>) {
      updated = currentResult.adjustedToItems(adjustment);
    }
    if (updated == null) return;

    final wasAdded = addedToDailyTotal;
    final previousAddedCalories = addedCaloriesSnapshot;

    setState(() {
      result = updated;
      mealConfirmed = true;
      if (wasAdded) {
        addedToDailyTotal = true;
        addedCaloriesSnapshot = updated!.caloriesKcal;
      } else {
        addedToDailyTotal = false;
        addedCaloriesSnapshot = null;
      }
    });

    if (wasAdded && previousAddedCalories != null) {
      final delta = updated.caloriesKcal - previousAddedCalories;
      if (delta != 0) {
        widget.onAdjustDailyKcal(delta);
      }
    }

    if (adjustment is int && adjustment > 0) {
      final message = wasAdded
          ? 'Portion auf $adjustment g angepasst. Tageswert aktualisiert.'
          : 'Portion auf $adjustment g angepasst.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } else if (adjustment is List<MealComponent>) {
      final message = wasAdded
          ? 'Bestandteile und Tageswert aktualisiert.'
          : 'Bestandteile und Gramm angepasst.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.92;
    final keyboardInset = mediaQuery.viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: const BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SheetHandle(),
            _SheetHeader(
              slot: widget.slot,
              onClose: () => Navigator.of(context).pop(),
            ),
            Flexible(
              child: SingleChildScrollView(
                key: const ValueKey('add-meal-sheet-scroll'),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuickActions(),
                    const SizedBox(height: 16),
                    _buildSearchField(),
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
                      for (var i = 0; i < productSuggestions.length; i++) ...[
                        _ProductSuggestionTile(
                          key: ValueKey('kcal-product-suggestion-$i'),
                          product: productSuggestions[i],
                          onTap: () => selectProduct(productSuggestions[i]),
                        ),
                        if (i != productSuggestions.length - 1)
                          const SizedBox(height: 8),
                      ],
                    ],
                    if (widget.favorites.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _FavoritesSection(
                        favorites: widget.favorites,
                        onPick: pickFavorite,
                        onRemove: widget.onRemoveFavorite,
                      ),
                    ],
                    const SizedBox(height: 18),
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
                      const _EmptyHint(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _SheetActionButton(
            key: const ValueKey('analyse-camera-button'),
            icon: Icons.photo_camera_rounded,
            label: 'Kamera',
            color: orange,
            filled: true,
            onPressed:
                isLoading ? null : () => pickAndAnalyze(ImageSource.camera),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SheetActionButton(
            key: const ValueKey('analyse-gallery-button'),
            icon: Icons.photo_library_outlined,
            label: 'Galerie',
            color: pink,
            onPressed:
                isLoading ? null : () => pickAndAnalyze(ImageSource.gallery),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SheetActionButton(
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

  Widget _buildSearchField() {
    return Container(
      key: const ValueKey('kcal-product-search-card'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.search_rounded, size: 18, color: lime),
              SizedBox(width: 8),
              Text(
                'PRODUKTSUCHE',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
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
              filled: true,
              fillColor: surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: hairline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: hairline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: lime),
              ),
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
        ],
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: hairline,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.slot, required this.onClose});

  final MealSlot slot;
  final VoidCallback onClose;

  Color get _color => switch (slot) {
        MealSlot.breakfast => orange,
        MealSlot.lunch => lime,
        MealSlot.dinner => pink,
        MealSlot.snack => cyan,
      };

  IconData get _icon => switch (slot) {
        MealSlot.breakfast => Icons.wb_sunny_outlined,
        MealSlot.lunch => Icons.light_mode_outlined,
        MealSlot.dinner => Icons.nights_stay_outlined,
        MealSlot.snack => Icons.cookie_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 8, 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon, color: _color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.label,
                  style: const TextStyle(
                    color: textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 1),
                const Text(
                  'Mahlzeit hinzufügen',
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: const ValueKey('add-meal-sheet-close'),
            onPressed: onClose,
            tooltip: 'Schließen',
            icon: const Icon(Icons.close_rounded, color: textMuted),
          ),
        ],
      ),
    );
  }
}

class _SheetActionButton extends StatelessWidget {
  const _SheetActionButton({
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
            color: filled ? color : surfaceSoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: filled ? color : color.withValues(alpha: 0.32),
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

class _ProductSuggestionTile extends StatelessWidget {
  const _ProductSuggestionTile({
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

class _FavoritesSection extends StatelessWidget {
  const _FavoritesSection({
    required this.favorites,
    required this.onPick,
    required this.onRemove,
  });

  final List<FavoriteMeal> favorites;
  final ValueChanged<MealAnalysisResult> onPick;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LETZTE MAHLZEITEN',
          style: TextStyle(
            color: textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < favorites.length; i++) ...[
          InkWell(
            key: ValueKey('favorite-tile-$i'),
            onTap: () => onPick(favorites[i].result),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
              decoration: BoxDecoration(
                color: surfaceSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: orange.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.bookmark_outline_rounded,
                      color: orange,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          favorites[i].result.mealName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${favorites[i].result.caloriesKcal} kcal · '
                          '${favorites[i].result.estimatedGrams} g',
                          style: const TextStyle(
                            color: textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => onRemove(favorites[i].id),
                    tooltip: 'Entfernen',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: textMuted,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (i != favorites.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: cyan,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Foto knipsen, Barcode scannen oder Produkt suchen — '
              'das Ergebnis erscheint direkt hier zum Bestätigen.',
              style: TextStyle(
                color: textPrimary,
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

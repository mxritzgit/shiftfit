import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/favorite_meal.dart';
import '../../models/logged_meal.dart';
import '../../models/meal_analysis_result.dart';
import '../../screens/barcode_scanner_screen.dart';
import '../../services/meal_analyzer.dart';
import '../../services/meal_photo_input.dart';
import '../../services/open_food_facts_product_service.dart';
import '../../theme/app_colors.dart';
import 'existing_meals_list.dart';
import 'meal_analysis_sheet.dart';
import 'meal_suggestion_item.dart';

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
  List<LoggedMeal> existingMeals = const <LoggedMeal>[],
  ValueChanged<String>? onRemoveMeal,
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
        existingMeals: existingMeals,
        onAdd: onAdd,
        onAdjustDailyKcal: onAdjustDailyKcal,
        onRemoveFavorite: onRemoveFavorite,
        onRemoveMeal: onRemoveMeal,
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
    this.existingMeals = const <LoggedMeal>[],
    this.onRemoveMeal,
  });

  final MealSlot slot;
  final MealAnalyzer analyzer;
  final ProductLookupService productService;
  final MealPhotoInput photoInput;
  final List<FavoriteMeal> favorites;
  final void Function(MealAnalysisResult, MealSlot) onAdd;
  final ValueChanged<int> onAdjustDailyKcal;
  final ValueChanged<String> onRemoveFavorite;
  final List<LoggedMeal> existingMeals;
  final ValueChanged<String>? onRemoveMeal;

  @override
  State<AddMealSheet> createState() => _AddMealSheetState();
}

class _AddMealSheetState extends State<AddMealSheet> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _productSearchDebounce;
  int _productSearchRequestId = 0;
  final Map<String, List<ProductSearchResult>> _productSearchCache =
      <String, List<ProductSearchResult>>{};
  List<ProductSearchResult> _productSuggestions =
      const <ProductSearchResult>[];
  bool _isSearchingProducts = false;
  String? _productSearchMessage;

  String? _expandedItemKey;
  final Set<String> _justAddedKeys = <String>{};
  final Map<String, Timer> _justAddedTimers = <String, Timer>{};

  late List<LoggedMeal> _existing;

  static const Duration _productSearchDebounceDelay =
      Duration(milliseconds: 1000);
  static const Duration _productSearchRetryDelay =
      Duration(milliseconds: 1500);
  static const int _productSearchMaxAttempts = 6;
  static const Duration _justAddedFadeDelay = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _existing = List<LoggedMeal>.of(widget.existingMeals);
  }

  @override
  void dispose() {
    _productSearchDebounce?.cancel();
    for (final t in _justAddedTimers.values) {
      t.cancel();
    }
    _justAddedTimers.clear();
    _searchController.dispose();
    super.dispose();
  }

  bool get _searchActive => _searchController.text.trim().length >= 2;

  void _removeExisting(String id) {
    setState(() {
      _existing = _existing.where((m) => m.id != id).toList();
    });
    widget.onRemoveMeal?.call(id);
  }

  // ─── Suche ────────────────────────────────────────────────────────────

  void _scheduleProductSearch(String value) {
    final query = value.trim();
    _productSearchDebounce?.cancel();

    if (query.length < 2) {
      _productSearchRequestId++;
      setState(() {
        _isSearchingProducts = false;
        _productSuggestions = const <ProductSearchResult>[];
        _productSearchMessage = null;
      });
      return;
    }

    // rebuild damit _searchActive umschaltet (Favoriten -> Treffer-Slot).
    setState(() {});
    _productSearchDebounce = Timer(
      _productSearchDebounceDelay,
      () => _searchProducts(queryOverride: query, showTransientError: false),
    );
  }

  Future<void> _searchProducts({
    String? queryOverride,
    bool showTransientError = true,
  }) async {
    _productSearchDebounce?.cancel();
    final query = (queryOverride ?? _searchController.text).trim();
    if (query.length < 2) {
      setState(() {
        _productSuggestions = const <ProductSearchResult>[];
        _productSearchMessage = 'Mindestens 2 Zeichen, z.B. Dr Oetker Salami.';
      });
      return;
    }

    final cacheKey = _normalizeQuery(query);
    final cached = _productSearchCache[cacheKey];
    if (cached != null) {
      _productSearchRequestId++;
      setState(() {
        _productSuggestions = cached;
        _isSearchingProducts = false;
        _productSearchMessage = cached.isEmpty
            ? 'Nichts gefunden. Versuche Marke + Produktname.'
            : null;
      });
      return;
    }

    final requestId = ++_productSearchRequestId;
    setState(() {
      _isSearchingProducts = true;
      _productSearchMessage = null;
    });

    try {
      final suggestions = await _searchWithRetry(query, requestId);
      if (!mounted) return;
      if (requestId != _productSearchRequestId ||
          query != _searchController.text.trim()) {
        return;
      }
      setState(() {
        _productSuggestions = suggestions;
        _isSearchingProducts = false;
        _productSearchMessage = suggestions.isEmpty
            ? 'Nichts gefunden. Versuche Marke + Produktname.'
            : null;
      });
    } catch (_) {
      if (!mounted) return;
      if (requestId != _productSearchRequestId ||
          query != _searchController.text.trim()) {
        return;
      }
      setState(() {
        _isSearchingProducts = false;
        _productSearchMessage = showTransientError
            ? 'OpenFoodFacts gerade nicht erreichbar.'
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
          _productSearchCache[_normalizeQuery(query)] = suggestions;
          return suggestions;
        }
        lastSuggestions = suggestions;
      } catch (error) {
        lastError = error;
      }

      if (attempt == _productSearchMaxAttempts - 1 ||
          requestId != _productSearchRequestId) {
        break;
      }
      await Future<void>.delayed(_productSearchRetryDelay);
    }

    if (lastError == null) return lastSuggestions;
    throw lastError;
  }

  static String _normalizeQuery(String query) =>
      query.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  // ─── Foto / Galerie / Barcode ─────────────────────────────────────────

  Future<void> _pickAndAnalyze(ImageSource source) async {
    MealPhotoSelection? selection;
    try {
      selection = await widget.photoInput.pick(source);
    } on PlatformException catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
          source == ImageSource.camera
              ? 'Kamera konnte nicht geöffnet werden. Prüfe die Berechtigung.'
              : 'Galerie konnte nicht geöffnet werden. Prüfe die Berechtigung.',
        )),
      );
      return;
    }
    if (selection == null || !mounted) return;

    await showMealAnalysisSheet(
      context,
      slot: widget.slot,
      resultFuture: widget.analyzer.analyze(selection.request),
      previewImage: selection.previewBytes,
      onAdd: widget.onAdd,
      onAdjustDailyKcal: widget.onAdjustDailyKcal,
      failureMessage:
          'Analyse fehlgeschlagen. Prüfe Internet, Supabase und OpenRouter.',
    );
  }

  Future<void> _scanBarcode() async {
    final barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    final trimmed = barcode?.trim();
    if (trimmed == null || trimmed.isEmpty || !mounted) return;

    await showMealAnalysisSheet(
      context,
      slot: widget.slot,
      resultFuture: widget.productService.lookupBarcode(trimmed),
      previewImage: null,
      onAdd: widget.onAdd,
      onAdjustDailyKcal: widget.onAdjustDailyKcal,
      failureMessage:
          'Barcode $trimmed nicht gefunden oder OpenFoodFacts nicht erreichbar.',
    );
  }

  // ─── Hinzufuegen ──────────────────────────────────────────────────────

  void _handleAdd(String itemKey, MealAnalysisResult result) {
    widget.onAdd(result, widget.slot);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
          '${result.caloriesKcal} kcal zu ${widget.slot.label} hinzugefügt.',
        )),
      );
    }
    setState(() {
      _expandedItemKey = null;
      _justAddedKeys.add(itemKey);
    });
    _justAddedTimers.remove(itemKey)?.cancel();
    _justAddedTimers[itemKey] = Timer(_justAddedFadeDelay, () {
      _justAddedTimers.remove(itemKey);
      if (!mounted) return;
      setState(() => _justAddedKeys.remove(itemKey));
    });
  }

  void _toggleExpanded(String key) {
    setState(() {
      _expandedItemKey = _expandedItemKey == key ? null : key;
    });
  }

  // ─── Build ────────────────────────────────────────────────────────────

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
              onCamera: () => _pickAndAnalyze(ImageSource.camera),
              onGallery: () => _pickAndAnalyze(ImageSource.gallery),
              onBarcode: _scanBarcode,
            ),
            _SearchBar(
              controller: _searchController,
              isSearching: _isSearchingProducts,
              onChanged: _scheduleProductSearch,
              onSubmitted: (_) => _searchProducts(),
              onSearchPressed: _searchProducts,
            ),
            Flexible(
              child: SingleChildScrollView(
                key: const ValueKey('add-meal-sheet-scroll'),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_existing.isNotEmpty) ...[
                      ExistingMealsList(
                        meals: _existing,
                        slot: widget.slot,
                        onRemove: widget.onRemoveMeal == null
                            ? null
                            : _removeExisting,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_searchActive)
                      _buildSearchResults()
                    else
                      _buildFavorites(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearchingProducts && _productSuggestions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: lime),
          ),
        ),
      );
    }
    if (_productSuggestions.isEmpty && _productSearchMessage != null) {
      return _HintBlock(text: _productSearchMessage!);
    }
    if (_productSuggestions.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Suchtreffer'),
        const SizedBox(height: 8),
        for (var i = 0; i < _productSuggestions.length; i++) ...[
          _suggestionItem(i),
          if (i != _productSuggestions.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _suggestionItem(int index) {
    final suggestion = _productSuggestions[index];
    final key = 'product:${suggestion.code}';
    return MealSuggestionItem(
      key: ValueKey('kcal-product-suggestion-$index'),
      result: suggestion.result,
      imageUrl: suggestion.imageUrl,
      fallbackIcon: Icons.fastfood_outlined,
      accent: lime,
      expanded: _expandedItemKey == key,
      justAdded: _justAddedKeys.contains(key),
      onTap: () => _toggleExpanded(key),
      onAdd: (result) => _handleAdd(key, result),
      addButtonKey: ValueKey('kcal-product-suggestion-add-$index'),
    );
  }

  Widget _buildFavorites() {
    if (widget.favorites.isEmpty) {
      return const _EmptyState();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Letzte Mahlzeiten'),
        const SizedBox(height: 8),
        for (var i = 0; i < widget.favorites.length; i++) ...[
          _favoriteItem(i),
          if (i != widget.favorites.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _favoriteItem(int index) {
    final favorite = widget.favorites[index];
    final key = 'favorite:${favorite.id}';
    return MealSuggestionItem(
      key: ValueKey('favorite-tile-$index'),
      result: favorite.result,
      fallbackIcon: Icons.bookmark_outline_rounded,
      accent: orange,
      expanded: _expandedItemKey == key,
      justAdded: _justAddedKeys.contains(key),
      onTap: () => _toggleExpanded(key),
      onAdd: (result) => _handleAdd(key, result),
      onRemove: () => widget.onRemoveFavorite(favorite.id),
      addButtonKey: ValueKey('favorite-tile-add-$index'),
    );
  }
}

// ─── Header ─────────────────────────────────────────────────────────────

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
  const _SheetHeader({
    required this.slot,
    required this.onClose,
    required this.onCamera,
    required this.onGallery,
    required this.onBarcode,
  });

  final MealSlot slot;
  final VoidCallback onClose;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onBarcode;

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
      padding: const EdgeInsets.fromLTRB(20, 4, 6, 10),
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
            child: Text(
              slot.label,
              style: const TextStyle(
                color: textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ),
          _HeaderIconButton(
            keyValue: const ValueKey('analyse-camera-button'),
            icon: Icons.photo_camera_rounded,
            color: orange,
            tooltip: 'Foto aufnehmen',
            onPressed: onCamera,
          ),
          _HeaderIconButton(
            keyValue: const ValueKey('analyse-gallery-button'),
            icon: Icons.photo_library_outlined,
            color: pink,
            tooltip: 'Aus Galerie',
            onPressed: onGallery,
          ),
          _HeaderIconButton(
            keyValue: const ValueKey('analyse-barcode-button'),
            icon: Icons.qr_code_scanner_rounded,
            color: cyan,
            tooltip: 'Barcode scannen',
            onPressed: onBarcode,
          ),
          const SizedBox(width: 2),
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

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.keyValue,
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  final Key keyValue;
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: keyValue,
      onPressed: onPressed,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      icon: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 17),
      ),
    );
  }
}

// ─── Search bar ─────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.isSearching,
    required this.onChanged,
    required this.onSubmitted,
    required this.onSearchPressed,
  });

  final TextEditingController controller;
  final bool isSearching;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onSearchPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('kcal-product-search-card'),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: surfaceSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: hairline),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            const Icon(Icons.search_rounded, size: 18, color: textMuted),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                key: const ValueKey('kcal-product-search-input'),
                controller: controller,
                autofocus: true,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                textInputAction: TextInputAction.search,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: 'Was hast du gegessen?',
                  hintStyle: TextStyle(
                    color: textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  isCollapsed: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            IconButton(
              key: const ValueKey('kcal-product-search-button'),
              onPressed: isSearching ? null : onSearchPressed,
              icon: isSearching
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: lime,
                      ),
                    )
                  : const Icon(Icons.arrow_forward_rounded,
                      size: 18, color: lime),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty / hint / labels ──────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _HintBlock extends StatelessWidget {
  const _HintBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: lime.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.restaurant_outlined, color: lime, size: 24),
          ),
          const SizedBox(height: 14),
          const Text(
            'Suche oben oder scanne einen Barcode',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Eingaben erscheinen direkt in der Liste oben.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}


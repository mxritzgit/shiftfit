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

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('screen-analyse'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ShiftFitTopBar(
          plan: ShiftFitPlan(
            recommendation: 'Meal AI',
            focus: 'KI Kalorienanalyse',
            tagline: 'Foto aufnehmen, grob einschätzen, bewusst nachjustieren.',
            totalMinutes: 0,
            intensity: 'Live',
            recoveryScore: 78,
            accent: orange,
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
              const StatusPill(label: 'Meal AI', color: orange),
              const SizedBox(height: 18),
              const Text(
                'Mahlzeit scannen',
                key: ValueKey('analyse-hero-title'),
                style: TextStyle(
                  fontSize: 40,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Foto aufnehmen für lose Mahlzeiten oder Barcode scannen für verpackte Produkte. Barcodes werden über OpenFoodFacts mit echten Nährwerten pro 100 g geladen.',
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

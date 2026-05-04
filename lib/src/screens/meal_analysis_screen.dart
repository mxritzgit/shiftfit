import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/meal_analysis_request.dart';
import '../models/meal_analysis_result.dart';
import '../models/shift_fit_plan.dart';
import '../services/meal_analyzer.dart';
import '../services/open_food_facts_product_service.dart';
import '../theme/app_colors.dart';
import '../widgets/common/basic_widgets.dart';
import '../widgets/meal/meal_widgets.dart';
import '../widgets/shared/shiftfit_top_bar.dart';
import 'barcode_scanner_screen.dart';

class MealAnalysisScreen extends StatefulWidget {
  const MealAnalysisScreen({super.key});

  @override
  State<MealAnalysisScreen> createState() => _MealAnalysisScreenState();
}

class _MealAnalysisScreenState extends State<MealAnalysisScreen> {
  final ImagePicker picker = ImagePicker();
  final MealAnalyzer analyzer = const EdgeFunctionMealAnalyzer();
  final MealAnalyzer demoAnalyzer = const DemoMealAnalyzer();
  final OpenFoodFactsProductService productService =
      const OpenFoodFactsProductService();
  Uint8List? selectedImageBytes;
  MealAnalysisResult? result;
  bool isLoading = false;
  bool mealConfirmed = false;

  Future<void> scanBarcode() async {
    final barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (barcode == null || barcode.trim().isEmpty || !mounted) {
      return;
    }

    await lookupBarcode(barcode.trim());
  }

  Future<void> runDemoBarcodeLookup() async {
    await lookupBarcode('4008400402222');
  }

  Future<void> lookupBarcode(String barcode) async {
    setState(() {
      selectedImageBytes = null;
      result = null;
      isLoading = true;
      mealConfirmed = false;
    });

    try {
      final lookupResult = await productService.lookupBarcode(barcode);
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
    XFile? image;
    try {
      image = await picker.pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1400,
      );
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

    if (image == null) {
      return;
    }

    Uint8List? bytes;
    try {
      bytes = await image.readAsBytes();
    } catch (_) {
      bytes = null;
    }

    await runAnalysis(
      MealAnalysisRequest(imageId: image.path, imageBytes: bytes),
      bytes,
    );
  }

  Future<void> runDemoAnalysis() async {
    await runAnalysis(
      const MealAnalysisRequest(imageId: 'manual-demo-analysis'),
      null,
      analyzerOverride: demoAnalyzer,
    );
  }

  Future<void> runAnalysis(
    MealAnalysisRequest request,
    Uint8List? imageBytes, {
    MealAnalyzer? analyzerOverride,
  }) async {
    setState(() {
      selectedImageBytes = imageBytes;
      result = null;
      isLoading = true;
      mealConfirmed = false;
    });

    try {
      final analysisResult = await (analyzerOverride ?? analyzer).analyze(request);
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

  Future<void> adjustMealPortion() async {
    final currentResult = result;
    if (currentResult == null) {
      return;
    }

    final adjustedGrams = await showWeightAdjustmentSheet(context, currentResult);
    if (adjustedGrams == null || adjustedGrams <= 0 || !mounted) {
      return;
    }

    setState(() {
      result = currentResult.adjustedToGrams(adjustedGrams);
      mealConfirmed = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Portion auf $adjustedGrams g angepasst.')),
    );
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
            intensity: 'Demo',
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
                key: const ValueKey('analyse-hero-title'),
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
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  TextButton.icon(
                    key: const ValueKey('analyse-demo-button'),
                    onPressed: isLoading ? null : runDemoAnalysis,
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text('Demo-Fotoanalyse'),
                    style: TextButton.styleFrom(
                      foregroundColor: cyan,
                      textStyle: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  TextButton.icon(
                    key: const ValueKey('analyse-demo-barcode-button'),
                    onPressed: isLoading ? null : runDemoBarcodeLookup,
                    icon: const Icon(Icons.inventory_2_rounded),
                    label: const Text('Demo-Barcode laden'),
                    style: TextButton.styleFrom(
                      foregroundColor: lime,
                      textStyle: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        MealPreviewCard(imageBytes: selectedImageBytes),
        const SizedBox(height: 18),
        if (isLoading)
          const MealLoadingCard()
        else if (result != null)
          MealResultCard(
            result: result!,
            confirmed: mealConfirmed,
            onConfirmed: confirmMealEstimate,
            onAdjustRequested: adjustMealPortion,
          )
        else
          const MealEmptyCard(),
      ],
    );
  }
}

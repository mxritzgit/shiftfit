import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  runApp(const ShiftFitApp());
}

const Color _bg = Color(0xFF080B10);
const Color _surface = Color(0xFF111927);
const Color _surfaceSoft = Color(0xFF172233);
const Color _lime = Color(0xFF9BFF67);
const Color _cyan = Color(0xFF63D8FF);
const Color _orange = Color(0xFFFFC266);
const Color _pink = Color(0xFFFF7DB8);

class ShiftFitApp extends StatelessWidget {
  const ShiftFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ShiftFit',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _lime,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: _bg,
        snackBarTheme: SnackBarThemeData(
          backgroundColor: _surfaceSoft,
          contentTextStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          behavior: SnackBarBehavior.floating,
        ),
        useMaterial3: true,
      ),
      home: const ShiftFitHomePage(),
    );
  }
}

class ShiftFitHomePage extends StatefulWidget {
  const ShiftFitHomePage({super.key});

  @override
  State<ShiftFitHomePage> createState() => _ShiftFitHomePageState();
}

class _ShiftFitHomePageState extends State<ShiftFitHomePage> {
  String selectedShift = 'Früh';
  String selectedEnergy = 'Normal';
  String selectedStress = 'Mittel';
  int selectedTab = 0;
  final List<String> weekPlan = [
    'Früh',
    'Früh',
    'Spät',
    'Spät',
    'Nacht',
    'Frei',
    'Frei',
  ];

  ShiftFitPlan get plan => ShiftFitPlan.from(
    shift: selectedShift,
    energy: selectedEnergy,
    stress: selectedStress,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: ShiftFitBottomNav(
        selectedIndex: selectedTab,
        onSelected: (index) => setState(() => selectedTab = index),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF111927), _bg],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            key: ValueKey('tab-scroll-$selectedTab'),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: _buildSelectedScreen(),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedScreen() {
    return switch (selectedTab) {
      1 => WeekPlannerScreen(
        plan: plan,
        weekPlan: weekPlan,
        onShiftChanged: (dayIndex, shift) {
          setState(() => weekPlan[dayIndex] = shift);
        },
      ),
      2 => TrendsScreen(plan: plan, weekPlan: weekPlan),
      3 => const MealAnalysisScreen(),
      _ => TodayDashboard(
        selectedShift: selectedShift,
        selectedEnergy: selectedEnergy,
        selectedStress: selectedStress,
        plan: plan,
        onShiftSelected: (value) => setState(() => selectedShift = value),
        onEnergySelected: (value) => setState(() => selectedEnergy = value),
        onStressSelected: (value) => setState(() => selectedStress = value),
      ),
    };
  }
}

class TodayDashboard extends StatelessWidget {
  const TodayDashboard({
    super.key,
    required this.selectedShift,
    required this.selectedEnergy,
    required this.selectedStress,
    required this.plan,
    required this.onShiftSelected,
    required this.onEnergySelected,
    required this.onStressSelected,
  });

  final String selectedShift;
  final String selectedEnergy;
  final String selectedStress;
  final ShiftFitPlan plan;
  final ValueChanged<String> onShiftSelected;
  final ValueChanged<String> onEnergySelected;
  final ValueChanged<String> onStressSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('screen-today'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShiftFitTopBar(plan: plan),
        const SizedBox(height: 24),
        ShiftFitHero(plan: plan),
        const SizedBox(height: 22),
        QuickCheckInCard(
          selectedShift: selectedShift,
          selectedEnergy: selectedEnergy,
          selectedStress: selectedStress,
          plan: plan,
          onShiftSelected: onShiftSelected,
          onEnergySelected: onEnergySelected,
          onStressSelected: onStressSelected,
        ),
        const SizedBox(height: 18),
        RecoveryScoreCard(plan: plan),
        const SizedBox(height: 18),
        SectionHeader(
          title: 'Dein Plan für heute',
          action: '${plan.totalMinutes} Min',
        ),
        const SizedBox(height: 12),
        DailyPlanCard(plan: plan),
        const SizedBox(height: 18),
        SectionHeader(
          title: 'Schicht-Kompass',
          action: selectedShift,
        ),
        const SizedBox(height: 12),
        ShiftTimeline(shift: selectedShift),
        const SizedBox(height: 18),
        const SectionHeader(title: 'Recovery Tools', action: '3 Basics'),
        const SizedBox(height: 12),
        RecoveryToolsGrid(plan: plan),
        const SizedBox(height: 18),
        const SectionHeader(title: 'Wochenrhythmus', action: 'Demo'),
        const SizedBox(height: 12),
        const RhythmWeekCard(),
      ],
    );
  }
}

class ShiftFitPlan {
  const ShiftFitPlan({
    required this.recommendation,
    required this.focus,
    required this.tagline,
    required this.totalMinutes,
    required this.intensity,
    required this.recoveryScore,
    required this.accent,
    required this.blocks,
    required this.sleepHint,
    required this.fuelHint,
    required this.breathHint,
  });

  final String recommendation;
  final String focus;
  final String tagline;
  final int totalMinutes;
  final String intensity;
  final int recoveryScore;
  final Color accent;
  final List<PlanBlock> blocks;
  final String sleepHint;
  final String fuelHint;
  final String breathHint;

  static ShiftFitPlan from({
    required String shift,
    required String energy,
    required String stress,
  }) {
    if (energy == 'Müde' || stress == 'Hoch') {
      return const ShiftFitPlan(
        recommendation: 'Recovery Flow',
        focus: 'Runterfahren statt durchbeißen',
        tagline: 'Sanfte Bewegung, Atmung und frühes Licht für dein Nervensystem.',
        totalMinutes: 18,
        intensity: 'Leicht',
        recoveryScore: 62,
        accent: _cyan,
        sleepHint: '90 Min vor Schlaf: Licht dimmen, Handy weg, Dusche warm.',
        fuelHint: 'Protein + warme Carbs. Koffein heute nur früh im Wachfenster.',
        breathHint: '4-7-8 Atmung: 4 Runden vor dem Hinlegen.',
        blocks: [
          PlanBlock('Mobility', '6 Min', Icons.self_improvement, 'Nacken, Hüfte, Rücken öffnen'),
          PlanBlock('Zone 1 Walk', '8 Min', Icons.directions_walk, 'Locker gehen, kein Pulsdruck'),
          PlanBlock('Breath Down', '4 Min', Icons.air, 'Lange Ausatmung, Schultern sinken lassen'),
        ],
      );
    }

    if (energy == 'Stark' && stress != 'Hoch') {
      return const ShiftFitPlan(
        recommendation: 'Kraft Session',
        focus: 'Kurz, schwer, sauber',
        tagline: 'Nutze das Energie-Fenster ohne dich für die nächste Schicht zu zerstören.',
        totalMinutes: 32,
        intensity: 'Stark',
        recoveryScore: 86,
        accent: _lime,
        sleepHint: 'Nach Training 10 Min Cooldown, später keine hellen Screens.',
        fuelHint: 'Vorher Snack, danach Protein + Elektrolyte.',
        breathHint: '2 Min Nasenatmung zwischen Arbeitssätzen.',
        blocks: [
          PlanBlock('Primer', '5 Min', Icons.flash_on, 'Gelenke wach, Core aktivieren'),
          PlanBlock('Strength', '22 Min', Icons.fitness_center, '3 Runden Kniebeuge, Push, Pull'),
          PlanBlock('Cooldown', '5 Min', Icons.spa, 'Puls runter, Hüfte öffnen'),
        ],
      );
    }

    if (shift == 'Nacht') {
      return const ShiftFitPlan(
        recommendation: 'Mobility Reset',
        focus: 'Wach bleiben ohne Overload',
        tagline: 'Beweglichkeit, kurze Aktivierung und klare Schlaf-Brücke nach der Nacht.',
        totalMinutes: 22,
        intensity: 'Moderat',
        recoveryScore: 74,
        accent: _pink,
        sleepHint: 'Nach Schicht Sonnenbrille, Zimmer kühl und dunkel.',
        fuelHint: 'Leicht essen: Joghurt, Banane, Nüsse oder Suppe.',
        breathHint: 'Box Breathing in der Pause: 4-4-4-4.',
        blocks: [
          PlanBlock('Reset', '7 Min', Icons.accessibility_new, 'Wirbelsäule und Hüfte mobilisieren'),
          PlanBlock('Carry', '10 Min', Icons.shopping_bag, 'Leichte Carries oder Treppe'),
          PlanBlock('Sleep Bridge', '5 Min', Icons.bedtime, 'Atmung + Licht aus Routine'),
        ],
      );
    }

    if (shift == 'Frei') {
      return const ShiftFitPlan(
        recommendation: 'Build & Recharge',
        focus: 'Etwas mehr Volumen, trotzdem smart',
        tagline: 'Freier Tag: Training, Meal Prep und ein stabiler Schlafanker.',
        totalMinutes: 40,
        intensity: 'Aufbau',
        recoveryScore: 81,
        accent: _orange,
        sleepHint: 'Schlafanker halten: maximal 60 Min später ins Bett.',
        fuelHint: 'Meal Prep: 2 Proteinbasen + 2 schnelle Carb-Optionen.',
        breathHint: '5 Min Spaziergang nach der größten Mahlzeit.',
        blocks: [
          PlanBlock('Warm-up', '8 Min', Icons.local_fire_department, 'Dynamisch mobilisieren'),
          PlanBlock('Full Body', '24 Min', Icons.fitness_center, '4 Runden Ganzkörper'),
          PlanBlock('Recharge', '8 Min', Icons.spa, 'Stretch + Plan für morgen'),
        ],
      );
    }

    return const ShiftFitPlan(
      recommendation: '20 Min Training',
      focus: 'Effektiv zwischen Arbeit und Leben',
      tagline: 'Ein knackiger Reiz mit genug Reserve für deine nächste Schicht.',
      totalMinutes: 20,
      intensity: 'Moderat',
      recoveryScore: 78,
      accent: _lime,
      sleepHint: 'Heute gleicher Schlafanker, auch wenn die Schicht früh startet.',
      fuelHint: 'Wasser + Salz, danach Protein. Koffein-Stopp 8 Std vor Schlaf.',
      breathHint: '3 Min langsame Nasenatmung nach dem Training.',
      blocks: [
        PlanBlock('Warm-up', '4 Min', Icons.local_fire_department, 'Gelenke wach, Puls leicht hoch'),
        PlanBlock('Circuit', '12 Min', Icons.repeat, 'Squat, Push, Hinge, Core'),
        PlanBlock('Downshift', '4 Min', Icons.air, 'Cooldown und Atmung'),
      ],
    );
  }
}

class PlanBlock {
  const PlanBlock(this.title, this.duration, this.icon, this.description);

  final String title;
  final String duration;
  final IconData icon;
  final String description;
}

Color _shiftColor(String shift) {
  return switch (shift) {
    'Früh' => _lime,
    'Spät' => _orange,
    'Nacht' => _pink,
    'Frei' => _cyan,
    _ => Colors.white,
  };
}

class MealAnalysisScreen extends StatefulWidget {
  const MealAnalysisScreen({super.key});

  @override
  State<MealAnalysisScreen> createState() => _MealAnalysisScreenState();
}

class _MealAnalysisScreenState extends State<MealAnalysisScreen> {
  final ImagePicker _picker = ImagePicker();
  final MealAnalyzer _analyzer = const EdgeFunctionMealAnalyzer();
  final MealAnalyzer _demoAnalyzer = const DemoMealAnalyzer();
  final OpenFoodFactsProductService _productService =
      const OpenFoodFactsProductService();
  Uint8List? _selectedImageBytes;
  MealAnalysisResult? _result;
  bool _isLoading = false;
  bool _mealConfirmed = false;

  Future<void> _scanBarcode() async {
    final barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (barcode == null || barcode.trim().isEmpty || !mounted) {
      return;
    }

    await _lookupBarcode(barcode.trim());
  }

  Future<void> _runDemoBarcodeLookup() async {
    await _lookupBarcode('4008400402222');
  }

  Future<void> _lookupBarcode(String barcode) async {
    setState(() {
      _selectedImageBytes = null;
      _result = null;
      _isLoading = true;
      _mealConfirmed = false;
    });

    try {
      final result = await _productService.lookupBarcode(barcode);
      if (!mounted) {
        return;
      }

      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Barcode $barcode nicht gefunden oder OpenFoodFacts ist nicht erreichbar.',
          ),
        ),
      );
    }
  }

  Future<void> _pickAndAnalyze(ImageSource source) async {
    XFile? image;
    try {
      image = await _picker.pickImage(
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

    await _runAnalysis(
      MealAnalysisRequest(imageId: image.path, imageBytes: bytes),
      bytes,
    );
  }

  Future<void> _runDemoAnalysis() async {
    await _runAnalysis(
      const MealAnalysisRequest(imageId: 'manual-demo-analysis'),
      null,
      analyzer: _demoAnalyzer,
    );
  }

  Future<void> _runAnalysis(
    MealAnalysisRequest request,
    Uint8List? imageBytes, {
    MealAnalyzer? analyzer,
  }) async {
    setState(() {
      _selectedImageBytes = imageBytes;
      _result = null;
      _isLoading = true;
      _mealConfirmed = false;
    });

    try {
      final result = await (analyzer ?? _analyzer).analyze(request);
      if (!mounted) {
        return;
      }

      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
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

  void _confirmMealEstimate() {
    setState(() => _mealConfirmed = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kalorienschätzung bestätigt.')),
    );
  }

  Future<void> _adjustMealPortion() async {
    final result = _result;
    if (result == null) {
      return;
    }

    final adjustedGrams = await _showWeightAdjustmentSheet(context, result);
    if (adjustedGrams == null || adjustedGrams <= 0 || !mounted) {
      return;
    }

    setState(() {
      _result = result.adjustedToGrams(adjustedGrams);
      _mealConfirmed = true;
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
            accent: _orange,
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
              const StatusPill(label: 'Meal AI', color: _orange),
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
                      onPressed: _isLoading
                          ? null
                          : () => _pickAndAnalyze(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_rounded),
                      label: const Text('Kamera'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _orange,
                        foregroundColor: _bg,
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
                      onPressed: _isLoading
                          ? null
                          : () => _pickAndAnalyze(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_rounded),
                      label: const Text('Galerie'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: _orange.withValues(alpha: 0.45)),
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
                  onPressed: _isLoading ? null : _scanBarcode,
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('Barcode scannen'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _cyan,
                    foregroundColor: _bg,
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
                    onPressed: _isLoading ? null : _runDemoAnalysis,
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text('Demo-Fotoanalyse'),
                    style: TextButton.styleFrom(
                      foregroundColor: _cyan,
                      textStyle: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  TextButton.icon(
                    key: const ValueKey('analyse-demo-barcode-button'),
                    onPressed: _isLoading ? null : _runDemoBarcodeLookup,
                    icon: const Icon(Icons.inventory_2_rounded),
                    label: const Text('Demo-Barcode laden'),
                    style: TextButton.styleFrom(
                      foregroundColor: _lime,
                      textStyle: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        MealPreviewCard(imageBytes: _selectedImageBytes),
        const SizedBox(height: 18),
        if (_isLoading)
          const MealLoadingCard()
        else if (_result != null)
          MealResultCard(
            result: _result!,
            confirmed: _mealConfirmed,
            onConfirmed: _confirmMealEstimate,
            onAdjustRequested: _adjustMealPortion,
          )
        else
          const MealEmptyCard(),
      ],
    );
  }
}

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.ean8, BarcodeFormat.ean13, BarcodeFormat.upcA],
  );
  bool _hasReturned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDetect(BarcodeCapture capture) {
    if (_hasReturned) {
      return;
    }

    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.trim().isNotEmpty) {
        _hasReturned = true;
        Navigator.of(context).pop(rawValue.trim());
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: Colors.white,
        title: const Text('Barcode scannen'),
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _handleDetect),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              key: const ValueKey('barcode-scanner-hint'),
              margin: const EdgeInsets.all(18),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _surface.withValues(alpha: 0.90),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _cyan.withValues(alpha: 0.35)),
              ),
              child: const Text(
                'Barcode auf der Packung in den Rahmen halten. ShiftFit lädt dann die Nährwerte aus OpenFoodFacts.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w800, height: 1.3),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 260,
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _cyan, width: 3),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: FilledButton.icon(
                key: const ValueKey('barcode-close-button'),
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
                label: const Text('Abbrechen'),
                style: FilledButton.styleFrom(
                  backgroundColor: _surfaceSoft,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MealAnalysisRequest {
  const MealAnalysisRequest({required this.imageId, this.imageBytes});

  final String imageId;
  final Uint8List? imageBytes;
}

abstract class MealAnalyzer {
  Future<MealAnalysisResult> analyze(MealAnalysisRequest request);
}

class EdgeFunctionMealAnalyzer implements MealAnalyzer {
  const EdgeFunctionMealAnalyzer();

  static const String _supabaseUrl = 'https://ftoozzvmduptrvrrrshb.supabase.co';
  static const String _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ0b296enZtZHVwdHJ2cnJyc2hiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc4NDEyOTAsImV4cCI6MjA5MzQxNzI5MH0.5kx8LowjRc8q8uWqJmUGU8ZjCnplSRDC1NGhm-oG7to';
  static const String _functionPath = '/functions/v1/analyze-meal';

  @override
  Future<MealAnalysisResult> analyze(MealAnalysisRequest request) async {
    final imageBytes = request.imageBytes;
    if (imageBytes == null || imageBytes.isEmpty) {
      throw const FormatException('No image bytes available for analysis.');
    }

    final client = HttpClient();
    try {
      final uri = Uri.parse('$_supabaseUrl$_functionPath');
      final httpRequest = await client.postUrl(uri);
      httpRequest.headers.contentType = ContentType.json;
      httpRequest.headers.set('apikey', _supabaseAnonKey);
      httpRequest.headers.set('Authorization', 'Bearer $_supabaseAnonKey');
      httpRequest.write(
        jsonEncode({
          'imageBase64': base64Encode(imageBytes),
          'note':
              'ShiftFit iOS Analyse. Bitte wenn möglich mealName, caloriesKcal, estimatedGrams, kcalPer100G, proteinG, carbsG, fatG, confidence und explanation als JSON zurückgeben. Keine exakte Vermessung behaupten; Portionsgröße als Schätzung markieren.',
        }),
      );

      final response = await httpRequest.close();
      final responseBody = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('Meal analysis failed: $responseBody');
      }

      final result = decoded['result'];
      if (result is! Map<String, dynamic>) {
        throw const FormatException('Unexpected analysis response.');
      }

      return MealAnalysisResult.fromEdgeFunction(result);
    } finally {
      client.close(force: true);
    }
  }
}

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

class DemoMealAnalyzer implements MealAnalyzer {
  const DemoMealAnalyzer();

  @override
  Future<MealAnalysisResult> analyze(MealAnalysisRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final index = request.imageId.codeUnits.fold<int>(
          0,
          (previous, value) => previous + value,
        ) %
        _templates.length;
    return _templates[index];
  }

  static const List<MealAnalysisResult> _templates = [
    MealAnalysisResult(
      mealName: 'Bowl mit Huhn und Reis',
      caloriesKcal: 690,
      estimatedGrams: 480,
      kcalPer100G: 144,
      protein: '38-48 g',
      carbs: '68-86 g',
      fat: '18-28 g',
      confidence: '72%',
      portionNotes:
          'Wirkt wie eine mittlere Bowl mit einer Handfläche Protein und etwa 1,5 Tassen Reis.',
    ),
    MealAnalysisResult(
      mealName: 'Pasta mit Tomatensauce',
      caloriesKcal: 615,
      estimatedGrams: 420,
      kcalPer100G: 146,
      protein: '18-28 g',
      carbs: '82-104 g',
      fat: '12-22 g',
      confidence: '68%',
      portionNotes:
          'Portion und Ölmenge sind visuell schwer zu trennen; Käse oder Öl kann die Spanne erhöhen.',
    ),
    MealAnalysisResult(
      mealName: 'Frühstücksteller',
      caloriesKcal: 510,
      estimatedGrams: 360,
      kcalPer100G: 142,
      protein: '20-32 g',
      carbs: '36-58 g',
      fat: '18-30 g',
      confidence: '70%',
      portionNotes:
          'Schätzung passt zu Eiern, Brot und etwas Fettquelle; Getränke sind nicht eingerechnet.',
    ),
  ];
}

class MealAnalysisResult {
  const MealAnalysisResult({
    required this.mealName,
    required this.caloriesKcal,
    required this.estimatedGrams,
    required this.kcalPer100G,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.confidence,
    required this.portionNotes,
    this.isAdjusted = false,
    this.sourceLabel = 'KI-Schätzung',
    this.barcode,
    this.brand,
  });

  final String mealName;
  final int caloriesKcal;
  final int estimatedGrams;
  final double kcalPer100G;
  final String protein;
  final String carbs;
  final String fat;
  final String confidence;
  final String portionNotes;
  final bool isAdjusted;
  final String sourceLabel;
  final String? barcode;
  final String? brand;

  String get kcalRange => '$caloriesKcal kcal';
  String get portionLabel => '$estimatedGrams g geschätzt';
  String get kcalPer100Label => '${kcalPer100G.round()} kcal / 100 g';

  MealAnalysisResult adjustedToGrams(int grams) {
    final factor = estimatedGrams <= 0 ? 1.0 : grams / estimatedGrams;
    final adjustedKcal = (kcalPer100G * grams / 100).round();
    return MealAnalysisResult(
      mealName: mealName,
      caloriesKcal: adjustedKcal,
      estimatedGrams: grams,
      kcalPer100G: kcalPer100G,
      protein: _scaleMacroText(protein, factor),
      carbs: _scaleMacroText(carbs, factor),
      fat: _scaleMacroText(fat, factor),
      confidence: confidence,
      portionNotes:
          'Manuell angepasst: $grams g statt der ursprünglichen Portion. Kalorien neu berechnet mit ${kcalPer100G.round()} kcal pro 100 g.',
      isAdjusted: true,
      sourceLabel: sourceLabel,
      barcode: barcode,
      brand: brand,
    );
  }

  factory MealAnalysisResult.fromEdgeFunction(Map<String, dynamic> json) {
    final mealName = json['mealName']?.toString() ?? 'Unbekannte Mahlzeit';
    final calories = _readInt(json, const [
          'caloriesKcal',
          'kcal',
          'calories',
          'estimatedCaloriesKcal',
        ]) ??
        _extractFirstInt(json['caloriesKcal']?.toString()) ??
        _extractFirstInt(json['calories']?.toString()) ??
        0;
    final estimatedGrams = _readInt(json, const [
          'estimatedGrams',
          'portionGrams',
          'grams',
          'weightG',
          'estimatedWeightG',
        ]) ??
        _estimateGramsFromText(json['explanation']?.toString()) ??
        150;
    final kcalPer100G = _readDouble(json, const [
          'kcalPer100G',
          'caloriesPer100G',
          'caloriesPer100g',
          'kcalPer100g',
        ]) ??
        _knownKcalPer100G(mealName) ??
        (estimatedGrams > 0 && calories > 0 ? calories * 100 / estimatedGrams : 52.0);
    final protein = json['proteinG'];
    final carbs = json['carbsG'];
    final fat = json['fatG'];
    final confidence = json['confidence']?.toString() ?? 'medium';

    return MealAnalysisResult(
      mealName: mealName,
      caloriesKcal: calories > 0 ? calories : (kcalPer100G * estimatedGrams / 100).round(),
      estimatedGrams: estimatedGrams,
      kcalPer100G: kcalPer100G,
      protein: protein == null ? '-' : '$protein g',
      carbs: carbs == null ? '-' : '$carbs g',
      fat: fat == null ? '-' : '$fat g',
      confidence: _formatConfidence(confidence),
      portionNotes: json['explanation']?.toString() ??
          'KI-Schätzung aus dem Foto. Die Größe wurde nicht exakt vermessen; bitte Portion bestätigen oder Gewicht anpassen.',
      sourceLabel: 'Foto-KI',
    );
  }

  factory MealAnalysisResult.fromOpenFoodFacts(
    Map<String, dynamic> product,
    String barcode,
  ) {
    final nutriments = product['nutriments'] is Map<String, dynamic>
        ? product['nutriments'] as Map<String, dynamic>
        : <String, dynamic>{};
    final productName = _firstNonEmptyString(product, const [
          'product_name',
          'generic_name',
        ]) ??
        'Produkt $barcode';
    final brand = _firstNonEmptyString(product, const ['brands']);
    final kcalPer100G = _readDouble(nutriments, const [
          'energy-kcal_100g',
          'energy_kcal_100g',
          'energy-kcal_value',
        ]) ??
        0;
    if (kcalPer100G <= 0) {
      throw const FormatException('OpenFoodFacts product has no kcal per 100 g.');
    }
    final servingGrams = _readDouble(product, const ['serving_quantity'])?.round() ??
        _estimateGramsFromText(product['serving_size']?.toString()) ??
        100;
    final calories = (kcalPer100G * servingGrams / 100).round();
    final protein100 = _readDouble(nutriments, const ['proteins_100g']);
    final carbs100 = _readDouble(nutriments, const ['carbohydrates_100g']);
    final fat100 = _readDouble(nutriments, const ['fat_100g']);
    final quantity = _firstNonEmptyString(product, const ['quantity']);
    final servingSize = _firstNonEmptyString(product, const ['serving_size']);
    final details = <String>[
      'OpenFoodFacts Barcode $barcode.',
      if (brand != null) 'Marke: $brand.',
      if (quantity != null) 'Packung: $quantity.',
      if (servingSize != null) 'Portion laut Datenbank: $servingSize.',
      'Nährwerte kommen aus der Produktdatenbank, nicht aus einer Foto-Schätzung.',
      'Du kannst das gegessene Gewicht weiter anpassen.',
    ].join(' ');

    return MealAnalysisResult(
      mealName: brand == null ? productName : '$productName · $brand',
      caloriesKcal: calories,
      estimatedGrams: servingGrams,
      kcalPer100G: kcalPer100G,
      protein: _macroForGrams(protein100, servingGrams),
      carbs: _macroForGrams(carbs100, servingGrams),
      fat: _macroForGrams(fat100, servingGrams),
      confidence: 'Datenbank',
      portionNotes: details,
      sourceLabel: 'OpenFoodFacts',
      barcode: barcode,
      brand: brand,
    );
  }

  static int? _readInt(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is int) {
        return value;
      }
      if (value is double) {
        return value.round();
      }
      if (value is String) {
        final parsed = _extractFirstInt(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }

  static double? _readDouble(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        final normalized = value.replaceAll(',', '.');
        final match = RegExp(r'\d+(?:\.\d+)?').firstMatch(normalized);
        if (match != null) {
          return double.tryParse(match.group(0)!);
        }
      }
    }
    return null;
  }

  static String? _firstNonEmptyString(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  static String _macroForGrams(double? per100G, int grams) {
    if (per100G == null) {
      return '-';
    }
    final value = per100G * grams / 100;
    final formatted = value >= 10 ? value.round().toString() : value.toStringAsFixed(1);
    return '${formatted.replaceAll('.', ',')} g';
  }

  static int? _extractFirstInt(String? value) {
    if (value == null) {
      return null;
    }
    final match = RegExp(r'\d+').firstMatch(value);
    return match == null ? null : int.tryParse(match.group(0)!);
  }

  static int? _estimateGramsFromText(String? value) {
    if (value == null) {
      return null;
    }
    final match = RegExp(r'(\d{2,4})\s*g').firstMatch(value.toLowerCase());
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  static double? _knownKcalPer100G(String mealName) {
    final lower = mealName.toLowerCase();
    if (lower.contains('apfel') || lower.contains('apple')) {
      return 52;
    }
    if (lower.contains('banane') || lower.contains('banana')) {
      return 89;
    }
    if (lower.contains('orange')) {
      return 47;
    }
    if (lower.contains('erdbeer') || lower.contains('strawberr')) {
      return 32;
    }
    return null;
  }

  static String _scaleMacroText(String value, double factor) {
    final match = RegExp(r'(\d+(?:[,.]\d+)?)').firstMatch(value);
    if (match == null) {
      return value;
    }
    final number = double.tryParse(match.group(1)!.replaceAll(',', '.'));
    if (number == null) {
      return value;
    }
    final scaled = number * factor;
    final formatted = scaled >= 10 ? scaled.round().toString() : scaled.toStringAsFixed(1);
    return value.replaceFirst(match.group(1)!, formatted.replaceAll('.', ','));
  }

  static String _formatConfidence(String value) {
    return switch (value.toLowerCase()) {
      'low' => 'niedrig',
      'medium' => 'mittel',
      'high' => 'hoch',
      _ => value,
    };
  }
}

class ShiftFitTopBar extends StatelessWidget {
  const ShiftFitTopBar({super.key, required this.plan});

  final ShiftFitPlan plan;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ShiftFit',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'Schichtarbeit. Training. Recovery.',
              style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: plan.accent.withValues(alpha: 0.45)),
          ),
          child: CircleAvatar(
            radius: 22,
            backgroundColor: plan.accent.withValues(alpha: 0.16),
            child: Icon(Icons.nightlight_round, color: plan.accent, size: 22),
          ),
        ),
      ],
    );
  }
}

class ShiftFitHero extends StatelessWidget {
  const ShiftFitHero({super.key, required this.plan});

  final ShiftFitPlan plan;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusPill(label: 'Für deinen Rhythmus', color: plan.accent),
          const SizedBox(height: 18),
          const Text(
            'Train smart.\nRecover better.',
            style: TextStyle(
              fontSize: 46,
              height: 0.98,
              fontWeight: FontWeight.w900,
              letterSpacing: -2.2,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Kurze Empfehlungen passend zu deiner Schicht.',
            style: TextStyle(
              fontSize: 17,
              height: 1.35,
              color: Colors.white.withValues(alpha: 0.64),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              MetricChip(icon: Icons.timer, label: '${plan.totalMinutes} Min'),
              MetricChip(icon: Icons.speed, label: plan.intensity),
              MetricChip(icon: Icons.favorite, label: '${plan.recoveryScore}% Readiness'),
            ],
          ),
        ],
      ),
    );
  }
}

class QuickCheckInCard extends StatelessWidget {
  const QuickCheckInCard({
    super.key,
    required this.selectedShift,
    required this.selectedEnergy,
    required this.selectedStress,
    required this.plan,
    required this.onShiftSelected,
    required this.onEnergySelected,
    required this.onStressSelected,
  });

  final String selectedShift;
  final String selectedEnergy;
  final String selectedStress;
  final ShiftFitPlan plan;
  final ValueChanged<String> onShiftSelected;
  final ValueChanged<String> onEnergySelected;
  final ValueChanged<String> onStressSelected;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Heute',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                ),
              ),
              StatusPill(label: 'Check-in', color: plan.accent),
            ],
          ),
          const SizedBox(height: 16),
          const FieldLabel('Schicht'),
          const SizedBox(height: 8),
          SegmentedOptions(
            options: const ['Früh', 'Spät', 'Nacht', 'Frei'],
            selectedValue: selectedShift,
            onSelected: onShiftSelected,
          ),
          const SizedBox(height: 14),
          const FieldLabel('Energie'),
          const SizedBox(height: 8),
          SegmentedOptions(
            options: const ['Müde', 'Normal', 'Stark'],
            selectedValue: selectedEnergy,
            onSelected: onEnergySelected,
          ),
          const SizedBox(height: 14),
          const FieldLabel('Stress'),
          const SizedBox(height: 8),
          SegmentedOptions(
            options: const ['Niedrig', 'Mittel', 'Hoch'],
            selectedValue: selectedStress,
            onSelected: onStressSelected,
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: plan.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: plan.accent.withValues(alpha: 0.22)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.recommendation,
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  plan.focus,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const ValueKey('today-open-plan'),
                    style: FilledButton.styleFrom(
                      backgroundColor: plan.accent,
                      foregroundColor: _bg,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: () => _showPlanSheet(context, plan),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text(
                      'Plan öffnen',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RecoveryScoreCard extends StatelessWidget {
  const RecoveryScoreCard({super.key, required this.plan});

  final ShiftFitPlan plan;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          SizedBox(
            width: 86,
            height: 86,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: plan.recoveryScore / 100,
                  strokeWidth: 9,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  color: plan.accent,
                  strokeCap: StrokeCap.round,
                ),
                Text(
                  '${plan.recoveryScore}',
                  style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recovery Score',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  plan.tagline,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.64),
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DailyPlanCard extends StatelessWidget {
  const DailyPlanCard({super.key, required this.plan});

  final ShiftFitPlan plan;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          for (var i = 0; i < plan.blocks.length; i++) ...[
            PlanBlockTile(block: plan.blocks[i], accent: plan.accent, index: i + 1),
            if (i != plan.blocks.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class PlanBlockTile extends StatelessWidget {
  const PlanBlockTile({
    super.key,
    required this.block,
    required this.accent,
    required this.index,
  });

  final PlanBlock block;
  final Color accent;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: accent.withValues(alpha: 0.16),
            child: Icon(block.icon, color: accent, size: 22),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$index. ${block.title}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 3),
                Text(
                  block.description,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.58)),
                ),
              ],
            ),
          ),
          Text(
            block.duration,
            style: TextStyle(color: accent, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class ShiftTimeline extends StatelessWidget {
  const ShiftTimeline({super.key, required this.shift});

  final String shift;

  List<String> get _events {
    switch (shift) {
      case 'Spät':
        return ['Licht', 'Training', 'Meal Prep', 'Schicht', 'Runterfahren'];
      case 'Nacht':
        return ['Nap', 'Aktivieren', 'Schicht', 'Sonnenbrille', 'Schlaf'];
      case 'Frei':
        return ['Schlafanker', 'Training', 'Einkauf', 'Recovery', 'Planung'];
      default:
        return ['Wach', 'Licht', 'Schicht', 'Training', 'Schlafanker'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = _events;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              for (var i = 0; i < events.length; i++) ...[
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: i == 2 ? _lime : Colors.white.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        events[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: i == 2 ? 0.95 : 0.58),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                if (i != events.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 27),
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Der Kompass zeigt dir, wann Training, Licht und Schlaf am wenigsten mit deiner Schicht kollidieren.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.58), height: 1.35),
          ),
        ],
      ),
    );
  }
}

class RecoveryToolsGrid extends StatelessWidget {
  const RecoveryToolsGrid({super.key, required this.plan});

  final ShiftFitPlan plan;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RecoveryToolCard(
          icon: Icons.bedtime,
          title: 'Sleep Anchor',
          body: plan.sleepHint,
          color: _pink,
        ),
        const SizedBox(height: 12),
        RecoveryToolCard(
          icon: Icons.restaurant,
          title: 'Fuel Reminder',
          body: plan.fuelHint,
          color: _orange,
        ),
        const SizedBox(height: 12),
        RecoveryToolCard(
          icon: Icons.air,
          title: 'Breath Reset',
          body: plan.breathHint,
          color: _cyan,
        ),
      ],
    );
  }
}

class RecoveryToolCard extends StatelessWidget {
  const RecoveryToolCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withValues(alpha: 0.14),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.62), height: 1.32),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RhythmWeekCard extends StatelessWidget {
  const RhythmWeekCard({super.key});

  @override
  Widget build(BuildContext context) {
    const days = [
      ('Mo', 'Früh', _lime),
      ('Di', 'Früh', _lime),
      ('Mi', 'Spät', _orange),
      ('Do', 'Spät', _orange),
      ('Fr', 'Nacht', _pink),
      ('Sa', 'Nacht', _pink),
      ('So', 'Frei', _cyan),
    ];

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (final day in days)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: day.$3.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: day.$3.withValues(alpha: 0.18)),
                    ),
                    child: Column(
                      children: [
                        Text(day.$1, style: const TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        RotatedBox(
                          quarterTurns: 3,
                          child: Text(
                            day.$2,
                            style: TextStyle(
                              color: day.$3,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Als nächstes: echte Wochenplanung, gespeicherte Check-ins und adaptive Empfehlungen.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.58), height: 1.35),
          ),
        ],
      ),
    );
  }
}

class WeekPlannerScreen extends StatelessWidget {
  const WeekPlannerScreen({
    super.key,
    required this.plan,
    required this.weekPlan,
    required this.onShiftChanged,
  });

  static const _days = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
  static const _shifts = ['Früh', 'Spät', 'Nacht', 'Frei'];

  final ShiftFitPlan plan;
  final List<String> weekPlan;
  final void Function(int dayIndex, String shift) onShiftChanged;

  int get trainingDays =>
      weekPlan.where((shift) => shift == 'Frei' || shift == 'Früh').length;

  int get nightBlocks => weekPlan.where((shift) => shift == 'Nacht').length;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('screen-week'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShiftFitTopBar(plan: plan),
        const SizedBox(height: 24),
        AppCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatusPill(label: 'Woche planen', color: _cyan),
              const SizedBox(height: 18),
              const Text(
                '7 Tage,\nsauber getaktet.',
                style: TextStyle(
                  fontSize: 40,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Wähle deine Schichten und halte Training, Licht und Schlaf realistisch.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.64),
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                icon: Icons.fitness_center,
                title: 'Training',
                value: '$trainingDays Tage',
                color: _lime,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SummaryCard(
                icon: Icons.nightlight_round,
                title: 'Nächte',
                value: '$nightBlocks geplant',
                color: _pink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const SectionHeader(title: 'Schichtplan', action: 'Antippen'),
        const SizedBox(height: 12),
        for (var dayIndex = 0; dayIndex < _days.length; dayIndex++) ...[
          WeekDayPlannerRow(
            day: _days[dayIndex],
            selectedShift: weekPlan[dayIndex],
            shifts: _shifts,
            onShiftChanged: (shift) => onShiftChanged(dayIndex, shift),
          ),
          if (dayIndex != _days.length - 1) const SizedBox(height: 10),
        ],
        const SizedBox(height: 18),
        const SectionHeader(title: 'Planungstipps', action: '3 Hinweise'),
        const SizedBox(height: 12),
        PlanningTipsCard(weekPlan: weekPlan),
      ],
    );
  }
}

class WeekDayPlannerRow extends StatelessWidget {
  const WeekDayPlannerRow({
    super.key,
    required this.day,
    required this.selectedShift,
    required this.shifts,
    required this.onShiftChanged,
  });

  final String day;
  final String selectedShift;
  final List<String> shifts;
  final ValueChanged<String> onShiftChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(day, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final shift in shifts)
                  ShiftChoiceChip(
                    key: ValueKey('week-$day-$shift'),
                    label: shift,
                    selected: shift == selectedShift,
                    color: _shiftColor(shift),
                    onTap: () => onShiftChanged(shift),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ShiftChoiceChip extends StatelessWidget {
  const ShiftChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color : Colors.black.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: selected ? 0.70 : 0.28)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? _bg : Colors.white.withValues(alpha: 0.78),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: Colors.white.withValues(alpha: 0.58))),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class PlanningTipsCard extends StatelessWidget {
  const PlanningTipsCard({super.key, required this.weekPlan});

  final List<String> weekPlan;

  @override
  Widget build(BuildContext context) {
    final nights = weekPlan.where((shift) => shift == 'Nacht').length;
    final freeDays = weekPlan.where((shift) => shift == 'Frei').length;
    final tips = [
      nights > 0
          ? 'Nach Nachtschichten: Sonnenbrille heimwärts, Schlafraum kühl und dunkel.'
          : 'Ohne Nachtschicht: Schlafanker möglichst konstant halten.',
      freeDays > 1
          ? 'Freie Tage eignen sich für Krafttraining und Meal Prep.'
          : 'Bei wenig frei: kurze Recovery-Sessions höher priorisieren.',
      'Härtere Einheiten auf Früh- oder freie Tage legen, Spätdienste eher mobilisieren.',
    ];

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          for (var i = 0; i < tips.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: _cyan.withValues(alpha: 0.16),
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(color: _cyan, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tips[i],
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.68),
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (i != tips.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class TrendsScreen extends StatelessWidget {
  const TrendsScreen({super.key, required this.plan, required this.weekPlan});

  final ShiftFitPlan plan;
  final List<String> weekPlan;

  int get _streak => 5 + weekPlan.where((shift) => shift == 'Frei').length;

  int get _loadBalance {
    final nights = weekPlan.where((shift) => shift == 'Nacht').length;
    final free = weekPlan.where((shift) => shift == 'Frei').length;
    return (74 + free * 4 - nights * 6).clamp(48, 94).toInt();
  }

  @override
  Widget build(BuildContext context) {
    final bars = [
      ('Mo', 0.72, _lime),
      ('Di', 0.78, _lime),
      ('Mi', 0.64, _orange),
      ('Do', 0.69, _orange),
      ('Fr', 0.54, _pink),
      ('Sa', 0.58, _pink),
      ('So', 0.86, _cyan),
    ];

    return Column(
      key: const ValueKey('screen-trends'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShiftFitTopBar(plan: plan),
        const SizedBox(height: 24),
        AppCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatusPill(label: 'Trends', color: _lime),
              const SizedBox(height: 18),
              const Text(
                'Readiness bleibt\nsteuerbar.',
                style: TextStyle(
                  fontSize: 40,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Deine Muster zeigen, wann Training zieht und wann Recovery mehr bringt.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.64),
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                icon: Icons.favorite,
                title: 'Readiness',
                value: '${plan.recoveryScore}%',
                color: plan.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SummaryCard(
                icon: Icons.local_fire_department,
                title: 'Streak',
                value: '$_streak Tage',
                color: _orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SummaryCard(
          icon: Icons.balance,
          title: 'Belastungsbalance',
          value: '$_loadBalance%',
          color: _cyan,
        ),
        const SizedBox(height: 18),
        const SectionHeader(title: 'Readiness Verlauf', action: '7 Tage'),
        const SizedBox(height: 12),
        TrendBarsCard(bars: bars),
        const SizedBox(height: 18),
        const SectionHeader(title: 'Insights', action: 'Aktuell'),
        const SizedBox(height: 12),
        InsightsCard(plan: plan, loadBalance: _loadBalance),
      ],
    );
  }
}

class TrendBarsCard extends StatelessWidget {
  const TrendBarsCard({super.key, required this.bars});

  final List<(String, double, Color)> bars;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      child: SizedBox(
        height: 150,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final bar in bars)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: bar.$2,
                          child: Container(
                            width: 18,
                            decoration: BoxDecoration(
                              color: bar.$3,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      bar.$1,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.62),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class InsightsCard extends StatelessWidget {
  const InsightsCard({super.key, required this.plan, required this.loadBalance});

  final ShiftFitPlan plan;
  final int loadBalance;

  @override
  Widget build(BuildContext context) {
    final insights = [
      plan.recoveryScore >= 80
          ? 'Heute ist genug Reserve für Kraft oder intensivere Intervalle da.'
          : 'Heute lohnt sich ein ruhiger Reset mehr als zusätzlicher Druck.',
      loadBalance >= 75
          ? 'Die Woche ist ausgewogen. Halte den Schlafanker stabil.'
          : 'Mehr Puffer einplanen: Mobility und kurze Spaziergänge statt Volumen.',
      'Koffein-Stopp und Lichtfenster bleiben deine stärksten Hebel.',
    ];

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          for (var i = 0; i < insights.length; i++) ...[
            Row(
              children: [
                Icon(i == 0 ? Icons.bolt : Icons.check_circle, color: i == 0 ? _lime : _cyan),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    insights[i],
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.68),
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (i != insights.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class MealPreviewCard extends StatelessWidget {
  const MealPreviewCard({super.key, required this.imageBytes});

  final Uint8List? imageBytes;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Foto', action: 'Preview'),
          const SizedBox(height: 12),
          Container(
            key: const ValueKey('analyse-image-preview'),
            height: 190,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: imageBytes == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.restaurant_menu_rounded,
                        color: Colors.white.withValues(alpha: 0.42),
                        size: 42,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Noch kein Bild ausgewählt',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.58),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  )
                : Image.memory(
                    imageBytes!,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),
          ),
        ],
      ),
    );
  }
}

class MealEmptyCard extends StatelessWidget {
  const MealEmptyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: _cyan.withValues(alpha: 0.14),
            child: const Icon(Icons.info_outline_rounded, color: _cyan),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Starte eine Fotoanalyse oder scanne einen Barcode. Verpackte Produkte nutzt ShiftFit über OpenFoodFacts mit kcal pro 100 g.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.68),
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MealLoadingCard extends StatelessWidget {
  const MealLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      key: ValueKey('analyse-loading'),
      padding: EdgeInsets.all(18),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 3, color: _orange),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'KI Kalorienanalyse läuft...',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class MealResultCard extends StatelessWidget {
  const MealResultCard({
    super.key,
    required this.result,
    required this.confirmed,
    required this.onConfirmed,
    required this.onAdjustRequested,
  });

  final MealAnalysisResult result;
  final bool confirmed;
  final VoidCallback onConfirmed;
  final VoidCallback onAdjustRequested;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      key: const ValueKey('analyse-result-card'),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Analyse-Ergebnis',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
              ),
              StatusPill(
                label: result.sourceLabel,
                color: result.sourceLabel == 'OpenFoodFacts' ? _cyan : _orange,
              ),
              const SizedBox(width: 8),
              StatusPill(
                label: confirmed ? 'bestätigt' : 'prüfen',
                color: confirmed ? _lime : _orange,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            result.mealName,
            key: const ValueKey('analyse-meal-name'),
            style: const TextStyle(
              fontSize: 28,
              height: 1.05,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  result.kcalRange,
                  key: const ValueKey('analyse-kcal-range'),
                  style: const TextStyle(
                    color: _orange,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                result.kcalPer100Label,
                key: const ValueKey('analyse-kcal-per-100'),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.58),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            key: const ValueKey('analyse-portion-confirm-box'),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _cyan.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _cyan.withValues(alpha: 0.22)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: _cyan.withValues(alpha: 0.14),
                  child: const Icon(Icons.scale_rounded, color: _cyan),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.isAdjusted
                            ? '${result.estimatedGrams} g manuell angepasst'
                            : 'Portion: ${result.portionLabel}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Bestätigen oder Gewicht anpassen. ShiftFit rechnet die kcal neu.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.62),
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  key: const ValueKey('analyse-confirm-button'),
                  onPressed: confirmed ? null : onConfirmed,
                  icon: Icon(
                    confirmed ? Icons.check_circle_rounded : Icons.check_rounded,
                  ),
                  label: Text(confirmed ? 'Bestätigt' : 'Bestätigen'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _lime,
                    foregroundColor: _bg,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  key: const ValueKey('analyse-adjust-button'),
                  onPressed: onAdjustRequested,
                  icon: const Icon(Icons.tune_rounded),
                  label: const Text('Anpassen'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: _orange.withValues(alpha: 0.45)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: MacroTile(label: 'Protein', value: result.protein, color: _lime),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MacroTile(label: 'Carbs', value: result.carbs, color: _cyan),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MacroTile(label: 'Fett', value: result.fat, color: _pink),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const FieldLabel('PORTION'),
          const SizedBox(height: 6),
          Text(
            result.portionNotes,
            key: const ValueKey('analyse-portion-notes'),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.68),
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            key: const ValueKey('analyse-disclaimer'),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _orange.withValues(alpha: 0.24)),
            ),
            child: const Text(
              'Disclaimer: Bildbasierte Kalorien- und Makro-Schätzungen sind nur Näherungen. Zutaten, Öl, Saucen und Portionsgröße können deutlich abweichen.',
              style: TextStyle(height: 1.35, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class MacroTile extends StatelessWidget {
  const MacroTile({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.58),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class ShiftFitBottomNav extends StatelessWidget {
  const ShiftFitBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_rounded, 'Heute'),
      (Icons.calendar_month_rounded, 'Woche'),
      (Icons.insights_rounded, 'Trends'),
      (Icons.document_scanner_rounded, 'Analyse'),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      decoration: BoxDecoration(
        color: _bg.withValues(alpha: 0.96),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: TextButton.icon(
                key: ValueKey('nav-${items[i].$2}'),
                onPressed: () => onSelected(i),
                icon: Icon(items[i].$1, size: 20),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(items[i].$2),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: i == selectedIndex ? _lime : Colors.white54,
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SegmentedOptions extends StatelessWidget {
  const SegmentedOptions({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
  });

  final List<String> options;
  final String selectedValue;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: OptionPill(
                key: ValueKey('option-$option'),
                label: option,
                selected: option == selectedValue,
                onTap: () => onSelected(option),
              ),
            ),
        ],
      ),
    );
  }
}

class OptionPill extends StatelessWidget {
  const OptionPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? _bg : Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = EdgeInsets.zero});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class MetricChip extends StatelessWidget {
  const MetricChip({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, required this.action});

  final String title;
  final String action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
        ),
        Text(
          action,
          style: const TextStyle(color: _lime, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.56),
        fontWeight: FontWeight.w900,
        fontSize: 12,
        letterSpacing: 0.6,
      ),
    );
  }
}

Future<int?> _showWeightAdjustmentSheet(
  BuildContext context,
  MealAnalysisResult result,
) {
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: _surface,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _MealWeightAdjustmentSheet(result: result),
  );
}

class _MealWeightAdjustmentSheet extends StatefulWidget {
  const _MealWeightAdjustmentSheet({required this.result});

  final MealAnalysisResult result;

  @override
  State<_MealWeightAdjustmentSheet> createState() =>
      _MealWeightAdjustmentSheetState();
}

class _MealWeightAdjustmentSheetState extends State<_MealWeightAdjustmentSheet> {
  late final TextEditingController _controller;
  late int _grams;

  @override
  void initState() {
    super.initState();
    _grams = widget.result.estimatedGrams;
    _controller = TextEditingController(text: _grams.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final kcal = (result.kcalPer100G * _grams / 100).round();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        22,
        6,
        22,
        28 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Portion anpassen',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            '${result.mealName}: Foto-Schätzung ${result.estimatedGrams} g, Basis ${result.kcalPer100Label}.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.66),
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            key: const ValueKey('analyse-weight-input'),
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Gewicht in Gramm',
              suffixText: 'g',
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.22),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _grams = int.tryParse(value) ?? widget.result.estimatedGrams;
              });
            },
          ),
          const SizedBox(height: 14),
          Container(
            key: const ValueKey('analyse-adjusted-kcal-preview'),
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _orange.withValues(alpha: 0.24)),
            ),
            child: Text(
              '$_grams g ≈ $kcal kcal',
              style: const TextStyle(
                color: _orange,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('analyse-save-weight-button'),
              onPressed: _grams <= 0 ? null : () => Navigator.pop(context, _grams),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Übernehmen'),
              style: FilledButton.styleFrom(
                backgroundColor: _orange,
                foregroundColor: _bg,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


void _showPlanSheet(BuildContext context, ShiftFitPlan plan) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: _surface,
    showDragHandle: true,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(22, 6, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              plan.recommendation,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              plan.tagline,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.65), height: 1.35),
            ),
            const SizedBox(height: 16),
            for (final block in plan.blocks) ...[
              Row(
                children: [
                  Icon(block.icon, color: plan.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${block.title} · ${block.duration}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${plan.recommendation} ist vorgemerkt.')),
                  );
                },
                child: const Text('Für heute vormerken'),
              ),
            ),
          ],
        ),
      );
    },
  );
}

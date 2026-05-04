import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/meal_analysis_result.dart';
import '../../theme/app_colors.dart';
import '../common/basic_widgets.dart';

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
            backgroundColor: cyan.withValues(alpha: 0.14),
            child: const Icon(Icons.info_outline_rounded, color: cyan),
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
            child: CircularProgressIndicator(strokeWidth: 3, color: orange),
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
                color: result.sourceLabel == 'OpenFoodFacts' ? cyan : orange,
              ),
              const SizedBox(width: 8),
              StatusPill(
                label: confirmed ? 'bestätigt' : 'prüfen',
                color: confirmed ? lime : orange,
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
                    color: orange,
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
              color: cyan.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: cyan.withValues(alpha: 0.22)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: cyan.withValues(alpha: 0.14),
                  child: const Icon(Icons.scale_rounded, color: cyan),
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
                    backgroundColor: lime,
                    foregroundColor: bg,
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
                    side: BorderSide(color: orange.withValues(alpha: 0.45)),
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
                child: MacroTile(label: 'Protein', value: result.protein, color: lime),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MacroTile(label: 'Carbs', value: result.carbs, color: cyan),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MacroTile(label: 'Fett', value: result.fat, color: pink),
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
              color: orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: orange.withValues(alpha: 0.24)),
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

Future<int?> showWeightAdjustmentSheet(
  BuildContext context,
  MealAnalysisResult result,
) {
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: surface,
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
              color: orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: orange.withValues(alpha: 0.24)),
            ),
            child: Text(
              '$_grams g ≈ $kcal kcal',
              style: const TextStyle(
                color: orange,
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
                backgroundColor: orange,
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
    );
  }
}

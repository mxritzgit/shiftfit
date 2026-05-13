import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/meal_analysis_result.dart';
import '../../models/meal_component.dart';
import '../../theme/app_colors.dart';
import '../common/basic_widgets.dart';

class MealPreviewCard extends StatelessWidget {
  const MealPreviewCard({super.key, required this.imageBytes});

  final Uint8List? imageBytes;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Foto', action: 'Preview'),
          const SizedBox(height: 10),
          Container(
            key: const ValueKey('analyse-image-preview'),
            height: 170,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: surfaceSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: imageBytes == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.restaurant_menu_outlined,
                        color: textMuted,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Noch kein Bild ausgewählt',
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
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

class MealDailyTotalCard extends StatelessWidget {
  const MealDailyTotalCard({
    super.key,
    required this.dailyConsumedKcal,
  });

  final int dailyConsumedKcal;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      key: const ValueKey('analyse-daily-kcal-card'),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: lime.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.local_fire_department_outlined,
              color: lime,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Heute konsumiert',
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$dailyConsumedKcal kcal',
                  key: const ValueKey('analyse-daily-kcal-total'),
                  style: const TextStyle(
                    color: textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
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

class MealEmptyCard extends StatelessWidget {
  const MealEmptyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.info_outline_rounded, color: cyan, size: 18),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Produkt suchen, Barcode scannen oder Foto aufnehmen — dann zur Tagesbilanz hinzufügen.',
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

class MealLoadingCard extends StatefulWidget {
  const MealLoadingCard({super.key});

  @override
  State<MealLoadingCard> createState() => _MealLoadingCardState();
}

class _MealLoadingCardState extends State<MealLoadingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress;
  int _stepIndex = 0;

  /// Roughly how long a vision-model analysis takes in practice. The progress
  /// bar fills linearly over this duration once and then stops — if the
  /// network call is still pending after that we just stay on the last stage
  /// (no looping back to 1/4).
  static const Duration _estimatedDuration = Duration(seconds: 7);

  static const List<(IconData, String)> _stages = [
    (Icons.image_search_rounded, 'Erkenne Lebensmittel...'),
    (Icons.straighten_rounded, 'Schätze Mengen...'),
    (Icons.calculate_rounded, 'Berechne Kalorien...'),
    (Icons.auto_awesome_rounded, 'Letzter Feinschliff...'),
  ];

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(
      vsync: this,
      duration: _estimatedDuration,
    )
      ..addListener(_handleTick)
      ..forward();
  }

  void _handleTick() {
    if (!mounted) return;
    final raw = (_progress.value * _stages.length).floor();
    final clamped = raw.clamp(0, _stages.length - 1);
    if (clamped != _stepIndex) {
      setState(() => _stepIndex = clamped);
    }
  }

  @override
  void dispose() {
    _progress
      ..removeListener(_handleTick)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stage = _stages[_stepIndex];
    final atFinalStage = _stepIndex == _stages.length - 1;
    return AppCard(
      key: const ValueKey('analyse-loading'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: orange.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(stage.$1, color: orange, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.25),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: Column(
                    key: ValueKey(_stepIndex),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        stage.$2,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        atFinalStage
                            ? 'Gleich fertig...'
                            : 'Schritt ${_stepIndex + 1} von ${_stages.length}',
                        style: const TextStyle(
                          color: textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: AnimatedBuilder(
              animation: _progress,
              builder: (context, _) => LinearProgressIndicator(
                // Cap the visible progress at 95 % so a long-running call
                // doesn't sit at "100 %" and feel stuck. Once it actually
                // finishes the parent removes the card.
                value: (_progress.value * 0.95).clamp(0.0, 0.95),
                minHeight: 3,
                backgroundColor: hairline,
                color: orange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MealResultCard extends StatefulWidget {
  const MealResultCard({
    super.key,
    required this.result,
    required this.confirmed,
    required this.addedToDailyTotal,
    required this.onConfirmed,
    required this.onAdjustRequested,
    required this.onAddToDailyRequested,
  });

  final MealAnalysisResult result;
  final bool confirmed;
  final bool addedToDailyTotal;
  final VoidCallback onConfirmed;
  final VoidCallback onAdjustRequested;
  final VoidCallback onAddToDailyRequested;

  @override
  State<MealResultCard> createState() => _MealResultCardState();
}

class _MealResultCardState extends State<MealResultCard> {
  int _previousKcal = 0;

  @override
  void didUpdateWidget(covariant MealResultCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.result.caloriesKcal != widget.result.caloriesKcal) {
      _previousKcal = oldWidget.result.caloriesKcal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final isBarcode = result.sourceLabel == 'OpenFoodFacts';

    return AppCard(
      key: const ValueKey('analyse-result-card'),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusPill(
                label: result.sourceLabel,
                color: isBarcode ? cyan : orange,
              ),
              const SizedBox(width: 6),
              StatusPill(
                label: widget.confirmed ? 'bestätigt' : 'prüfen',
                color: widget.confirmed ? lime : orange,
              ),
              const Spacer(),
              IconButton(
                key: const ValueKey('analyse-info-button'),
                onPressed: () => _showInfo(context),
                tooltip: 'Details',
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            result.mealName,
            key: const ValueKey('analyse-meal-name'),
            style: const TextStyle(
              fontSize: 20,
              height: 1.15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _AnimatedKcal(
                  from: _previousKcal,
                  to: result.caloriesKcal,
                ),
              ),
              Text(
                result.kcalPer100Label,
                key: const ValueKey('analyse-kcal-per-100'),
                style: const TextStyle(
                  color: textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _PortionLine(result: result),
          if (result.hasItemizedBreakdown) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FieldLabel(
                    'BESTANDTEILE · ${result.items.length}',
                  ),
                ),
                const Text(
                  'einzeln anpassen über "Anpassen"',
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _ItemBreakdownList(items: result.items),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: MacroTile(
                  label: 'Protein',
                  value: result.protein,
                  color: lime,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: MacroTile(
                  label: 'Carbs',
                  value: result.carbs,
                  color: cyan,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: MacroTile(
                  label: 'Fett',
                  value: result.fat,
                  color: pink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  key: const ValueKey('analyse-confirm-button'),
                  onPressed: widget.confirmed ? null : widget.onConfirmed,
                  icon: Icon(
                    widget.confirmed
                        ? Icons.check_circle_rounded
                        : Icons.check_rounded,
                    size: 17,
                  ),
                  label: Text(
                    widget.confirmed ? 'Bestätigt' : 'Bestätigen',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: lime,
                    foregroundColor: bg,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  key: const ValueKey('analyse-adjust-button'),
                  onPressed: widget.onAdjustRequested,
                  icon: const Icon(Icons.tune_rounded, size: 17),
                  label: Text(
                    result.hasItemizedBreakdown ? 'Bestandteile' : 'Anpassen',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textPrimary,
                    side: const BorderSide(color: hairline),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('analyse-add-daily-button'),
              onPressed: widget.addedToDailyTotal
                  ? null
                  : widget.onAddToDailyRequested,
              icon: Icon(
                widget.addedToDailyTotal
                    ? Icons.check_circle_rounded
                    : Icons.add_circle_outline_rounded,
                size: 17,
              ),
              label: Text(
                widget.addedToDailyTotal
                    ? 'Zu heute hinzugefügt'
                    : 'Zu heute hinzufügen',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: cyan,
                foregroundColor: bg,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfo(BuildContext context) {
    final result = widget.result;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: surface,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result.mealName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 12),
              if (result.brand != null && result.brand!.isNotEmpty)
                _InfoLine(label: 'Marke', value: result.brand!),
              if (result.barcode != null && result.barcode!.isNotEmpty)
                _InfoLine(label: 'Barcode', value: result.barcode!),
              _InfoLine(
                label: 'Quelle',
                value: result.sourceLabel,
              ),
              _InfoLine(
                label: 'Sicherheit',
                value: result.confidence,
              ),
              const SizedBox(height: 12),
              Text(
                result.portionNotes,
                key: const ValueKey('analyse-portion-notes'),
                style: const TextStyle(
                  color: textPrimary,
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: surfaceSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Schätzungen sind Näherungen. Zutaten, Öl und Portion können abweichen.',
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: const TextStyle(
                color: textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PortionLine extends StatelessWidget {
  const _PortionLine({required this.result});

  final MealAnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final String label;
    if (result.hasItemizedBreakdown) {
      label = result.isAdjusted
          ? '${result.estimatedGrams} g über Einzelposten angepasst'
          : '${result.items.length} Bestandteile · ${result.estimatedGrams} g';
    } else if (result.isAdjusted) {
      label = '${result.estimatedGrams} g manuell angepasst';
    } else {
      label = 'Portion: ${result.portionLabel}';
    }
    return Padding(
      key: const ValueKey('analyse-portion-confirm-box'),
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        label,
        style: const TextStyle(
          color: textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _AnimatedKcal extends StatelessWidget {
  const _AnimatedKcal({required this.from, required this.to});

  final int from;
  final int to;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: from.toDouble(), end: to.toDouble()),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Text(
          '${value.round()} kcal',
          key: const ValueKey('analyse-kcal-range'),
          style: const TextStyle(
            color: orange,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
          ),
        );
      },
    );
  }
}

class _ItemBreakdownList extends StatelessWidget {
  const _ItemBreakdownList({required this.items});

  final List<MealComponent> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('analyse-item-breakdown'),
      children: [
        for (var index = 0; index < items.length; index++) ...[
          _ItemBreakdownRow(item: items[index], index: index),
          if (index < items.length - 1) const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class _ItemBreakdownRow extends StatelessWidget {
  const _ItemBreakdownRow({required this.item, required this.index});

  final MealComponent item;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('analyse-item-row-$index'),
      padding: const EdgeInsets.fromLTRB(14, 11, 12, 11),
      decoration: BoxDecoration(
        color: surfaceSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            item.gramsLabel,
            style: const TextStyle(
              color: textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            item.caloriesLabel,
            style: const TextStyle(
              color: orange,
              fontSize: 13,
              fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: surfaceSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

Future<Object?> showWeightAdjustmentSheet(
  BuildContext context,
  MealAnalysisResult result,
) {
  return showModalBottomSheet<Object>(
    context: context,
    backgroundColor: surface,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _MealItemAdjustmentSheet(result: result),
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
        20,
        4,
        20,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Portion anpassen',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${result.mealName} · ${result.kcalPer100Label}',
            style: const TextStyle(
              color: textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            key: const ValueKey('analyse-weight-input'),
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Gewicht in Gramm',
              suffixText: 'g',
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
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: surfaceSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: orange.withValues(alpha: 0.18)),
            ),
            child: Text(
              '$_grams g ≈ $kcal kcal',
              style: const TextStyle(
                color: orange,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('analyse-save-weight-button'),
              onPressed: _grams <= 0 ? null : () => Navigator.pop(context, _grams),
              icon: const Icon(Icons.check_rounded, size: 17),
              label: const Text(
                'Übernehmen',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: orange,
                foregroundColor: bg,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MealItemAdjustmentSheet extends StatefulWidget {
  const _MealItemAdjustmentSheet({required this.result});

  final MealAnalysisResult result;

  @override
  State<_MealItemAdjustmentSheet> createState() => _MealItemAdjustmentSheetState();
}

class _MealItemAdjustmentSheetState extends State<_MealItemAdjustmentSheet> {
  late final List<MealComponent> _items;
  late final List<TextEditingController> _controllers;
  late final List<int> _grams;
  Set<int> _removed = const <int>{};

  @override
  void initState() {
    super.initState();
    // Fall back to a single synthesized item when the AI didn't return any
    // itemized breakdown (or for OpenFoodFacts barcode lookups). The user can
    // then still edit the weight, remove it, or split it into multiple items
    // via "Bestandteil hinzufügen".
    if (widget.result.items.isNotEmpty) {
      _items = [...widget.result.items];
    } else {
      _items = [
        MealComponent(
          name: widget.result.mealName,
          grams: widget.result.estimatedGrams,
          caloriesKcal: widget.result.caloriesKcal,
          kcalPer100G: widget.result.kcalPer100G,
        ),
      ];
    }
    _grams = _items.map((item) => item.grams).toList(growable: true);
    _controllers = _grams
        .map((grams) => TextEditingController(text: grams.toString()))
        .toList(growable: true);
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _remove(int index) {
    setState(() => _removed = {..._removed, index});
  }

  void _undoRemove(int index) {
    setState(() => _removed = {..._removed}..remove(index));
  }

  void _appendItem(MealComponent item) {
    setState(() {
      _items.add(item);
      _grams.add(item.grams);
      _controllers.add(TextEditingController(text: item.grams.toString()));
    });
  }

  Future<void> _addItemDialog() async {
    final newItem = await showDialog<MealComponent>(
      context: context,
      builder: (context) => const _AddItemDialog(),
    );
    if (newItem != null) {
      _appendItem(newItem);
    }
  }

  int _itemKcalFor(int index) {
    final item = _items[index];
    final grams = _grams[index];
    final per100 = item.kcalPer100G;
    if (per100 != null && per100 > 0) {
      return (per100 * grams / 100).round();
    }
    if (item.grams > 0) {
      return (item.caloriesKcal * grams / item.grams).round();
    }
    return item.caloriesKcal;
  }

  String _statusLine(int addedCount) {
    final parts = <String>[];
    if (_removed.isNotEmpty) parts.add('${_removed.length} entfernt');
    if (addedCount > 0) parts.add('$addedCount manuell ergänzt');
    if (parts.isEmpty) {
      return 'Pro Lebensmittel das Gewicht anpassen oder mit X entfernen.';
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final adjustedItems = <MealComponent>[
      for (var index = 0; index < _items.length; index++)
        if (!_removed.contains(index))
          _items[index].adjustedToGrams(_grams[index]),
    ];
    final totalGrams = adjustedItems.fold<int>(
      0,
      (sum, item) => sum + item.grams,
    );
    final totalKcal = adjustedItems.fold<int>(
      0,
      (sum, item) => sum + item.caloriesKcal,
    );
    final invalidGrams = [
      for (var index = 0; index < _items.length; index++)
        if (!_removed.contains(index) && _grams[index] <= 0) index,
    ];
    final canSave = adjustedItems.isNotEmpty && invalidGrams.isEmpty;
    final addedCount = _items.length - widget.result.items.length;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bestandteile anpassen',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _statusLine(addedCount),
              style: const TextStyle(
                color: textMuted,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 18),
            for (var index = 0; index < _items.length; index++) ...[
              if (_removed.contains(index))
                _RemovedItemCard(
                  name: _items[index].name,
                  onUndo: () => _undoRemove(index),
                )
              else
                _ItemEditCard(
                  index: index,
                  item: _items[index],
                  controller: _controllers[index],
                  liveKcal: _itemKcalFor(index),
                  liveGrams: _grams[index],
                  onGramsChanged: (g) =>
                      setState(() => _grams[index] = g),
                  onRemove: () => _remove(index),
                ),
              const SizedBox(height: 10),
            ],
            OutlinedButton.icon(
              key: const ValueKey('analyse-item-add-button'),
              onPressed: _addItemDialog,
              icon: const Icon(Icons.add_rounded, size: 17),
              label: const Text(
                'Bestandteil hinzufügen',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: cyan,
                side: BorderSide(color: cyan.withValues(alpha: 0.45)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              key: const ValueKey('analyse-adjusted-kcal-preview'),
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: surfaceSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: orange.withValues(alpha: 0.18)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calculate_outlined,
                    color: orange,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$totalGrams g ≈ $totalKcal kcal',
                      style: const TextStyle(
                        color: orange,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (adjustedItems.isNotEmpty)
                    Text(
                      '${adjustedItems.length} Posten',
                      style: const TextStyle(
                        color: textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            if (adjustedItems.isEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Mindestens ein Bestandteil muss übrig bleiben.',
                style: TextStyle(
                  color: pink,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const ValueKey('analyse-save-weight-button'),
                onPressed: canSave
                    ? () => Navigator.pop(context, adjustedItems)
                    : null,
                icon: const Icon(Icons.check_rounded, size: 17),
                label: const Text(
                  'Übernehmen',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: orange,
                  foregroundColor: bg,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemEditCard extends StatelessWidget {
  const _ItemEditCard({
    required this.index,
    required this.item,
    required this.controller,
    required this.liveKcal,
    required this.liveGrams,
    required this.onGramsChanged,
    required this.onRemove,
  });

  final int index;
  final MealComponent item;
  final TextEditingController controller;
  final int liveKcal;
  final int liveGrams;
  final ValueChanged<int> onGramsChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('analyse-item-card-$index'),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: surfaceSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              IconButton(
                key: ValueKey('analyse-item-remove-$index'),
                onPressed: onRemove,
                tooltip: 'Entfernen',
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: textMuted,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: TextField(
              key: ValueKey('analyse-item-weight-input-$index'),
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Gewicht',
                suffixText: 'g',
                helperText:
                    'Ursprünglich ${item.gramsLabel} · ${item.caloriesLabel}',
                helperStyle: const TextStyle(
                  color: textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onChanged: (value) {
                final parsed = int.tryParse(value) ?? 0;
                onGramsChanged(parsed);
              },
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Row(
              children: [
                const Icon(
                  Icons.local_fire_department_outlined,
                  size: 14,
                  color: orange,
                ),
                const SizedBox(width: 6),
                Text(
                  '$liveGrams g · $liveKcal kcal',
                  style: const TextStyle(
                    color: orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.kcalPer100G != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '· ${item.kcalPer100G!.round()} kcal/100g',
                    style: const TextStyle(
                      color: textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RemovedItemCard extends StatelessWidget {
  const _RemovedItemCard({required this.name, required this.onUndo});

  final String name;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: surfaceSoft.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: hairline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textMuted,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: onUndo,
            style: TextButton.styleFrom(
              foregroundColor: cyan,
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.undo_rounded, size: 14),
            label: const Text(
              'Wiederherstellen',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddItemDialog extends StatefulWidget {
  const _AddItemDialog();

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  final _name = TextEditingController();
  final _grams = TextEditingController();
  final _kcal = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _grams.dispose();
    _kcal.dispose();
    super.dispose();
  }

  bool get _isValid {
    if (_name.text.trim().isEmpty) return false;
    final g = int.tryParse(_grams.text.trim());
    final k = int.tryParse(_kcal.text.trim());
    return g != null && g > 0 && k != null && k >= 0;
  }

  void _submit() {
    final name = _name.text.trim();
    final grams = int.tryParse(_grams.text.trim()) ?? 0;
    final kcal = int.tryParse(_kcal.text.trim()) ?? 0;
    if (name.isEmpty || grams <= 0) return;
    final per100 = grams > 0 ? kcal * 100 / grams : null;
    Navigator.pop(
      context,
      MealComponent(
        name: name,
        grams: grams,
        caloriesKcal: kcal,
        kcalPer100G: per100,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Bestandteil hinzufügen',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manuell — wenn die KI etwas übersehen hat.',
              style: TextStyle(
                color: textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const ValueKey('analyse-add-item-name'),
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'z. B. Tomate',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('analyse-add-item-grams'),
                    controller: _grams,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Gewicht',
                      suffixText: 'g',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    key: const ValueKey('analyse-add-item-kcal'),
                    controller: _kcal,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Kalorien',
                      suffixText: 'kcal',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: textMuted),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          key: const ValueKey('analyse-add-item-save'),
          onPressed: _isValid ? _submit : null,
          style: FilledButton.styleFrom(
            backgroundColor: cyan,
            foregroundColor: bg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Hinzufügen',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

import 'dart:async';
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
  Timer? _stepTimer;
  late final AnimationController _pulse;
  int _stepIndex = 0;

  static const List<(IconData, String)> _stages = [
    (Icons.image_search_rounded, 'Erkenne Lebensmittel...'),
    (Icons.straighten_rounded, 'Schätze Mengen...'),
    (Icons.calculate_rounded, 'Berechne Kalorien...'),
    (Icons.auto_awesome_rounded, 'Letzter Feinschliff...'),
  ];

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _stepTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      if (!mounted) return;
      setState(() => _stepIndex = (_stepIndex + 1) % _stages.length);
    });
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stage = _stages[_stepIndex];
    return AppCard(
      key: const ValueKey('analyse-loading'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FadeTransition(
                opacity: Tween<double>(begin: 0.5, end: 1.0).animate(_pulse),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: orange.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(stage.$1, color: orange, size: 18),
                ),
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
                        'Schritt ${_stepIndex + 1} von ${_stages.length}',
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
            child: LinearProgressIndicator(
              value: (_stepIndex + 1) / _stages.length,
              minHeight: 3,
              backgroundColor: hairline,
              color: orange,
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
  final ValueChanged<Set<int>> onAdjustRequested;
  final VoidCallback onAddToDailyRequested;

  @override
  State<MealResultCard> createState() => _MealResultCardState();
}

class _MealResultCardState extends State<MealResultCard> {
  Set<int> _selected = const <int>{};
  int _previousKcal = 0;

  @override
  void initState() {
    super.initState();
    _previousKcal = 0;
  }

  @override
  void didUpdateWidget(covariant MealResultCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.result != widget.result) {
      _previousKcal = oldWidget.result.caloriesKcal;
      // Clear selection when the result swaps for a different meal.
      if (oldWidget.result.mealName != widget.result.mealName) {
        _selected = const <int>{};
      }
    }
  }

  void _toggle(int index) {
    setState(() {
      final next = {..._selected};
      if (next.contains(index)) {
        next.remove(index);
      } else {
        next.add(index);
      }
      _selected = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final isBarcode = result.sourceLabel == 'OpenFoodFacts';
    final selectionCount = _selected.length;
    final adjustLabel = selectionCount == 0
        ? (result.hasItemizedBreakdown ? 'Anpassen' : 'Anpassen')
        : '$selectionCount anpassen';

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
                const Expanded(child: FieldLabel('BESTANDTEILE')),
                if (selectionCount > 0)
                  Text(
                    '$selectionCount ausgewählt',
                    style: const TextStyle(
                      color: orange,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  )
                else
                  const Text(
                    'tippen zum auswählen',
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.4,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            _ItemBreakdownList(
              items: result.items,
              selected: _selected,
              onToggle: _toggle,
            ),
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
                  onPressed: () => widget.onAdjustRequested(_selected),
                  icon: const Icon(Icons.tune_rounded, size: 17),
                  label: Text(
                    adjustLabel,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: selectionCount > 0 ? orange : textPrimary,
                    side: BorderSide(
                      color: selectionCount > 0
                          ? orange.withValues(alpha: 0.45)
                          : hairline,
                    ),
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
  const _ItemBreakdownList({
    required this.items,
    required this.selected,
    required this.onToggle,
  });

  final List<MealComponent> items;
  final Set<int> selected;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('analyse-item-breakdown'),
      children: [
        for (var index = 0; index < items.length; index++) ...[
          _ItemBreakdownRow(
            item: items[index],
            index: index,
            selected: selected.contains(index),
            onTap: () => onToggle(index),
          ),
          if (index < items.length - 1) const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class _ItemBreakdownRow extends StatelessWidget {
  const _ItemBreakdownRow({
    required this.item,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  final MealComponent item;
  final int index;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey('analyse-item-row-$index'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(14, 11, 12, 11),
        decoration: BoxDecoration(
          color: selected ? orange.withValues(alpha: 0.10) : surfaceSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? orange.withValues(alpha: 0.45) : hairline,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.gramsLabel} · ${item.caloriesLabel}',
                    style: const TextStyle(
                      color: textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: selected ? orange : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: selected ? orange : textMuted.withValues(alpha: 0.45),
                ),
              ),
              child: selected
                  ? Icon(Icons.check_rounded, color: bg, size: 14)
                  : null,
            ),
          ],
        ),
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
  MealAnalysisResult result, {
  Set<int> editableIndices = const <int>{},
}) {
  return showModalBottomSheet<Object>(
    context: context,
    backgroundColor: surface,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => result.hasItemizedBreakdown
        ? _MealItemAdjustmentSheet(
            result: result,
            editableIndices: editableIndices,
          )
        : _MealWeightAdjustmentSheet(result: result),
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
  const _MealItemAdjustmentSheet({
    required this.result,
    this.editableIndices = const <int>{},
  });

  final MealAnalysisResult result;

  /// Indices of items the user can edit in this sheet. Empty means all items
  /// are editable (the "no selection → adjust everything" default).
  final Set<int> editableIndices;

  @override
  State<_MealItemAdjustmentSheet> createState() => _MealItemAdjustmentSheetState();
}

class _MealItemAdjustmentSheetState extends State<_MealItemAdjustmentSheet> {
  late final List<TextEditingController> _controllers;
  late List<int> _grams;
  late final Set<int> _editable;

  @override
  void initState() {
    super.initState();
    _grams = widget.result.items.map((item) => item.grams).toList(growable: true);
    _controllers = _grams
        .map((grams) => TextEditingController(text: grams.toString()))
        .toList(growable: false);
    _editable = widget.editableIndices.isEmpty
        ? {for (var i = 0; i < widget.result.items.length; i++) i}
        : widget.editableIndices;
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adjustedItems = [
      for (var index = 0; index < widget.result.items.length; index++)
        widget.result.items[index].adjustedToGrams(_grams[index]),
    ];
    final totalGrams = adjustedItems.fold<int>(0, (sum, item) => sum + item.grams);
    final totalKcal = adjustedItems.fold<int>(
      0,
      (sum, item) => sum + item.caloriesKcal,
    );

    final editableList = <int>[
      for (var i = 0; i < widget.result.items.length; i++)
        if (_editable.contains(i)) i,
    ];
    final unchangedCount = widget.result.items.length - editableList.length;

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
              unchangedCount > 0
                  ? '${editableList.length} ausgewählt · $unchangedCount unverändert.'
                  : 'Gramm pro Lebensmittel anpassen.',
              style: const TextStyle(
                color: textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 18),
            for (final index in editableList) ...[
              Text(
                widget.result.items[index].name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                key: ValueKey('analyse-item-weight-input-$index'),
                controller: _controllers[index],
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Gewicht in Gramm',
                  suffixText: 'g',
                  helperText:
                      '${widget.result.items[index].caloriesKcal} kcal bei ${widget.result.items[index].grams} g',
                ),
                onChanged: (value) {
                  setState(() {
                    _grams[index] = int.tryParse(value) ?? widget.result.items[index].grams;
                  });
                },
              ),
              const SizedBox(height: 12),
            ],
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
                '$totalGrams g ≈ $totalKcal kcal',
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
                onPressed: _grams.any((grams) => grams <= 0)
                    ? null
                    : () => Navigator.pop(context, adjustedItems),
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

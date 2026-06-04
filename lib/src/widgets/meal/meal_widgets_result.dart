part of 'meal_widgets.dart';

class MealResultCard extends StatefulWidget {
  const MealResultCard({
    super.key,
    required this.result,
    required this.addedToDailyTotal,
    required this.onAdjustRequested,
    required this.onAddToDailyRequested,
    this.isFavorite = false,
    this.onToggleFavorite,
  });

  final MealAnalysisResult result;
  final bool addedToDailyTotal;
  final VoidCallback onAdjustRequested;
  final VoidCallback onAddToDailyRequested;

  /// Ob diese Mahlzeit aktuell als Favorit markiert ist (Herz gefüllt).
  final bool isFavorite;

  /// Optionaler Toggle für den Favoriten-Herz-Button. Null → Button wird
  /// ausgeblendet (bestehende Aufrufer ohne Verdrahtung bleiben unverändert).
  final ValueChanged<MealAnalysisResult>? onToggleFavorite;

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
              const Spacer(),
              if (widget.onToggleFavorite != null)
                IconButton(
                  key: const ValueKey('analyse-favorite-button'),
                  onPressed: () => widget.onToggleFavorite!(result),
                  tooltip: widget.isFavorite
                      ? 'Aus Favoriten entfernen'
                      : 'Als Favorit speichern',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    widget.isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_outline_rounded,
                    size: 19,
                    color: widget.isFavorite ? lime : textMuted,
                  ),
                ),
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
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _PortionLine(result: result),
          if (result.hasItemizedBreakdown) ...[
            const SizedBox(height: 14),
            FieldLabel('BESTANDTEILE · ${result.items.length}'),
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
                  color: macroFat,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 56,
                child: OutlinedButton(
                  key: const ValueKey('analyse-adjust-button'),
                  onPressed: widget.onAdjustRequested,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textPrimary,
                    side: const BorderSide(color: hairline),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(rControl),
                    ),
                  ),
                  child: const Icon(Icons.tune_rounded, size: 18),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  key: const ValueKey('analyse-add-daily-button'),
                  onPressed: widget.addedToDailyTotal
                      ? null
                      : widget.onAddToDailyRequested,
                  icon: Icon(
                    widget.addedToDailyTotal
                        ? Icons.check_circle_rounded
                        : Icons.add_circle_outline_rounded,
                    size: 18,
                  ),
                  label: Text(
                    widget.addedToDailyTotal
                        ? 'Zu heute hinzugefügt'
                        : 'Hinzufügen',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: lime,
                    foregroundColor: bg,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(rControl),
                    ),
                  ),
                ),
              ),
            ],
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
                  borderRadius: BorderRadius.circular(rControl),
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
          fontFeatures: [FontFeature.tabularFigures()],
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
            height: 1.0,
            fontFeatures: [FontFeature.tabularFigures()],
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
        borderRadius: BorderRadius.circular(rControl),
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
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            item.caloriesLabel,
            style: const TextStyle(
              color: orange,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
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
        borderRadius: BorderRadius.circular(rControl),
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
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../models/logged_meal.dart';
import '../../models/meal_analysis_result.dart';
import '../../models/meal_component.dart';
import '../../theme/app_colors.dart';
import '../../theme/meal_slot_style.dart';
import '../common/app_snack.dart';
import '../meal/meal_widgets.dart';

/// Sub-Sheet fuer die Foto-/Barcode-Analyse. Wird vom AddMealSheet
/// gestartet sobald ein Bild aufgenommen oder ein Barcode gescannt wurde.
/// Zeigt das Loading-Card, danach die `MealResultCard` mit Anpassen +
/// Hinzufuegen — der Bestaetigen-Schritt entfaellt.
Future<void> showMealAnalysisSheet(
  BuildContext context, {
  required MealSlot slot,
  required Future<MealAnalysisResult> resultFuture,
  required Uint8List? previewImage,
  required void Function(MealAnalysisResult, MealSlot) onAdd,
  required ValueChanged<int> onAdjustDailyKcal,
  required String failureMessage,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (sheetContext) {
      return MealAnalysisSheet(
        slot: slot,
        resultFuture: resultFuture,
        previewImage: previewImage,
        onAdd: onAdd,
        onAdjustDailyKcal: onAdjustDailyKcal,
        failureMessage: failureMessage,
      );
    },
  );
}

class MealAnalysisSheet extends StatefulWidget {
  const MealAnalysisSheet({
    super.key,
    required this.slot,
    required this.resultFuture,
    required this.previewImage,
    required this.onAdd,
    required this.onAdjustDailyKcal,
    required this.failureMessage,
  });

  final MealSlot slot;
  final Future<MealAnalysisResult> resultFuture;
  final Uint8List? previewImage;
  final void Function(MealAnalysisResult, MealSlot) onAdd;
  final ValueChanged<int> onAdjustDailyKcal;
  final String failureMessage;

  @override
  State<MealAnalysisSheet> createState() => _MealAnalysisSheetState();
}

class _MealAnalysisSheetState extends State<MealAnalysisSheet> {
  MealAnalysisResult? _result;
  bool _isLoading = true;
  bool _addedToDailyTotal = false;
  int? _addedCaloriesSnapshot;

  @override
  void initState() {
    super.initState();
    _loadResult();
  }

  Future<void> _loadResult() async {
    try {
      final value = await widget.resultFuture;
      if (!mounted) return;
      setState(() {
        _result = value;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showAppSnack(context, widget.failureMessage,
          icon: Icons.error_outline_rounded,
          accent: danger,
          duration: kSnackError);
      Navigator.of(context).maybePop();
    }
  }

  void _addToDaily() {
    final result = _result;
    if (result == null || _addedToDailyTotal) return;
    widget.onAdd(result, widget.slot);
    setState(() {
      _addedToDailyTotal = true;
      _addedCaloriesSnapshot = result.caloriesKcal;
    });
    showAppSnack(
      context,
      '${result.caloriesKcal} kcal zu ${widget.slot.label} hinzugefügt.',
      icon: Icons.check_circle_rounded,
      accent: lime,
    );
  }

  Future<void> _adjustPortion() async {
    final current = _result;
    if (current == null) return;

    final adjustment = await showWeightAdjustmentSheet(context, current);
    if (!mounted || adjustment == null) return;

    MealAnalysisResult? candidate;
    if (adjustment is int && adjustment > 0) {
      candidate = current.adjustedToGrams(adjustment);
    } else if (adjustment is List<MealComponent>) {
      candidate = current.adjustedToItems(adjustment);
    }
    if (candidate == null) return;
    final updated = candidate;

    final wasAdded = _addedToDailyTotal;
    final previousAddedCalories = _addedCaloriesSnapshot;

    setState(() {
      _result = updated;
      if (wasAdded) {
        _addedCaloriesSnapshot = updated.caloriesKcal;
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
          ? '$adjustment g angepasst. Tageswert aktualisiert.'
          : '$adjustment g angepasst.';
      showAppSnack(context, message,
          icon: Icons.tune_rounded, accent: lime);
    } else if (adjustment is List<MealComponent>) {
      final message = wasAdded
          ? '${updated.estimatedGrams} g über Einzelposten angepasst. Tageswert aktualisiert.'
          : '${updated.estimatedGrams} g über Einzelposten angepasst.';
      showAppSnack(context, message,
          icon: Icons.tune_rounded, accent: lime);
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(rSheet)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SheetHandle(),
            _Header(slot: widget.slot, onClose: () => Navigator.of(context).pop()),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  28 + mediaQuery.viewPadding.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.previewImage != null) ...[
                      MealPreviewCard(imageBytes: widget.previewImage),
                      const SizedBox(height: 14),
                    ],
                    if (_isLoading)
                      const MealLoadingCard()
                    else if (_result != null)
                      MealResultCard(
                        result: _result!,
                        addedToDailyTotal: _addedToDailyTotal,
                        onAdjustRequested: _adjustPortion,
                        onAddToDailyRequested: _addToDaily,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
          borderRadius: BorderRadius.circular(rPill),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.slot, required this.onClose});

  final MealSlot slot;
  final VoidCallback onClose;

  Color get _color => slot.accent;

  IconData get _icon => slot.icon;

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
              borderRadius: BorderRadius.circular(rControl),
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
                const SizedBox(height: 2),
                const Text(
                  'Analyse prüfen',
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: const ValueKey('analyse-sheet-close'),
            onPressed: onClose,
            tooltip: 'Schließen',
            icon: const Icon(Icons.close_rounded, color: textMuted),
          ),
        ],
      ),
    );
  }
}

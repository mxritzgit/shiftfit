import 'package:flutter/material.dart';

import '../models/favorite_meal.dart';
import '../models/logged_meal.dart';
import '../models/macro_progress.dart';
import '../models/meal_analysis_result.dart';
import '../models/user_profile.dart';
import '../services/meal_analyzer.dart';
import '../services/meal_photo_input.dart';
import '../services/fallback_product_service.dart';
import '../services/meilisearch_product_service.dart';
import '../services/open_food_facts_product_service.dart';
import '../theme/app_colors.dart';
import '../widgets/kcal/add_meal_sheet.dart';
import '../widgets/kcal/calories_overview_card.dart';

class MealAnalysisScreen extends StatelessWidget {
  MealAnalysisScreen({
    super.key,
    MealAnalyzer? analyzer,
    ProductLookupService? productService,
    MealPhotoInput? photoInput,
    required this.dailyConsumedKcal,
    this.macroProgress = MacroProgress.empty,
    this.profile = const UserProfile(),
    this.favorites = const <FavoriteMeal>[],
    this.loggedMeals = const <LoggedMeal>[],
    this.burnedKcal = 0,
    DateTime? selectedDate,
    ValueChanged<DateTime>? onDateSelected,
    this.visiblePastDays = 4,
    void Function(MealAnalysisResult, MealSlot)? onAddMeal,
    ValueChanged<int>? onAdjustDailyKcal,
    ValueChanged<String>? onRemoveFavorite,
    ValueChanged<String>? onRemoveMeal,
  }) : analyzer = analyzer ?? const EdgeFunctionMealAnalyzer(),
       productService = productService ?? _defaultProductService(),
       photoInput = photoInput ?? DeviceMealPhotoInput(),
       selectedDate = DateUtils.dateOnly(selectedDate ?? DateTime.now()),
       onDateSelected = onDateSelected ?? _noopDate,
       onAddMeal = onAddMeal ?? _noopAdd,
       onAdjustDailyKcal = onAdjustDailyKcal ?? _noopInt,
       onRemoveFavorite = onRemoveFavorite ?? _noopString,
       onRemoveMeal = onRemoveMeal ?? _noopString;

  static void _noopAdd(MealAnalysisResult _, MealSlot __) {}
  static void _noopDate(DateTime _) {}
  static void _noopInt(int _) {}
  static void _noopString(String _) {}

  // Fast EU mirror (Meilisearch via Cloud Run proxy) with live OFF as fallback.
  static ProductLookupService _defaultProductService() =>
      FallbackProductService(
        MeilisearchProductService(),
        const OpenFoodFactsProductService(),
      );

  final MealAnalyzer analyzer;
  final ProductLookupService productService;
  final MealPhotoInput photoInput;
  final int dailyConsumedKcal;
  final MacroProgress macroProgress;
  final UserProfile profile;
  final List<FavoriteMeal> favorites;
  final List<LoggedMeal> loggedMeals;
  final int burnedKcal;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final int visiblePastDays;
  final void Function(MealAnalysisResult, MealSlot) onAddMeal;
  final ValueChanged<int> onAdjustDailyKcal;
  final ValueChanged<String> onRemoveFavorite;
  final ValueChanged<String> onRemoveMeal;

  void _openAddSheet(BuildContext context, MealSlot slot,
      {bool searchMode = false}) {
    // Bereits geloggte Eintraege fuer DIESEN Slot UND das aktuell angezeigte
    // Datum - das Sheet zeigt sie oben mit X-Button. Im Such-Modus entfaellt
    // dieses Slot-Framing (reine Suche, kein "Fruehstueck hinzufuegen").
    final existingForSlot = searchMode
        ? const <LoggedMeal>[]
        : loggedMeals
            .where((m) =>
                DateUtils.isSameDay(m.loggedAt, selectedDate) && m.slot == slot)
            .toList(growable: false);
    showAddMealSheet(
      context,
      slot: slot,
      searchMode: searchMode,
      analyzer: analyzer,
      productService: productService,
      photoInput: photoInput,
      favorites: favorites,
      existingMeals: existingForSlot,
      onAdd: onAddMeal,
      onAdjustDailyKcal: onAdjustDailyKcal,
      onRemoveFavorite: onRemoveFavorite,
      onRemoveMeal: onRemoveMeal,
    );
  }

  // Slot-Heuristik fuer die Sheet-Oeffner (Suche + Action-Buttons). Deckt sich
  // mit LoggedMeal.slot, damit ein neuer Eintrag im richtigen Slot landet.
  MealSlot _heuristicSlot() {
    final h = DateTime.now().hour;
    if (h < 11) return MealSlot.breakfast;
    if (h < 15) return MealSlot.lunch;
    if (h < 21) return MealSlot.dinner;
    return MealSlot.snack;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boundedHeight = constraints.hasBoundedHeight;

        final calsCard = CaloriesOverviewCard(
          dailyConsumedKcal: dailyConsumedKcal,
          kcalGoal: profile.dailyKcalGoal,
          burnedKcal: burnedKcal,
          macroProgress: macroProgress,
          profile: profile,
        );

        final historyCard = MealsTodayCard(
          meals: loggedMeals,
          onMealTap: (slot) => _openAddSheet(context, slot),
        );

        final children = <Widget>[
          const _KcalHeader(),
          SizedBox(height: boundedHeight ? 6 : 4),
          _FoodDateStrip(
            selectedDate: selectedDate,
            pastDays: visiblePastDays,
            onSelected: onDateSelected,
          ),
          SizedBox(height: boundedHeight ? 8 : 10),
          // Glass-Kalorienkarte mit inline-Makros (hoehen-begrenzt im Tab).
          if (boundedHeight)
            Expanded(flex: 46, child: calsCard)
          else
            calsCard,
          const SizedBox(height: 10),
          // Add-Block: FESTE Hoehe, NICHT Expanded -> sitzt klar oben,
          // damit Such-Launcher + Action-Buttons ohne Scroll hit-testbar sind.
          _FoodAddBlock(
            onSearch: () => _openAddSheet(context, _heuristicSlot(),
                searchMode: true),
            onBarcode: () => _openAddSheet(context, _heuristicSlot()),
            onAiScan: () => _openAddSheet(context, _heuristicSlot()),
            onQuick: () => _openAddSheet(context, _heuristicSlot()),
          ),
          const SizedBox(height: 10),
          // Verlauf: einzige unten wachsende Sektion.
          if (boundedHeight)
            Expanded(flex: 40, child: historyCard)
          else
            historyCard,
        ];

        return SizedBox(
          key: const ValueKey('kcal-page-fill'),
          height: boundedHeight ? constraints.maxHeight : null,
          child: Column(
            key: const ValueKey('screen-kcal-tracker'),
            mainAxisSize: boundedHeight ? MainAxisSize.max : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        );
      },
    );
  }
}

/// Add-Block (feste Hoehe): readonly Such-Launcher + 3 Action-Buttons.
/// Alle Tap-Ziele oeffnen NUR das bestehende AddMealSheet (keine Inline-
/// Ergebnisse, kein FAB). Keine Entrance-Opacity/Transform -> hit-testbar.
class _FoodAddBlock extends StatelessWidget {
  const _FoodAddBlock({
    required this.onSearch,
    required this.onBarcode,
    required this.onAiScan,
    required this.onQuick,
  });

  final VoidCallback onSearch;
  final VoidCallback onBarcode;
  final VoidCallback onAiScan;
  final VoidCallback onQuick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _FoodSearchBar(onTap: onSearch),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _FoodActionButton(
                key: const ValueKey('food-action-barcode'),
                icon: Icons.qr_code_scanner_rounded,
                label: 'Barcode\nscannen',
                filled: false,
                onTap: onBarcode,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FoodActionButton(
                key: const ValueKey('food-action-ai'),
                icon: Icons.add_a_photo_rounded,
                label: 'KI-Scan',
                filled: true,
                onTap: onAiScan,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FoodActionButton(
                key: const ValueKey('food-action-quick'),
                icon: Icons.bolt_rounded,
                label: 'Schnell\nhinzufügen',
                filled: false,
                onTap: onQuick,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Readonly Such-Launcher (KEIN echtes TextField) -> oeffnet das Add-Sheet.
class _FoodSearchBar extends StatelessWidget {
  const _FoodSearchBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const ValueKey('food-search'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(rControl),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(rControl),
          border: Border.all(color: hairline),
        ),
        child: Row(
          children: const [
            Icon(Icons.search_rounded, size: 18, color: textMuted),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Lebensmittel oder Mahlzeiten suchen…',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kompakter Action-Button: Outline (filled:false) oder gefuelltes forgeLime
/// (filled:true). Keine Entrance-Animation -> stabil hit-testbar.
class _FoodActionButton extends StatelessWidget {
  const _FoodActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color fg = filled ? bg : textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(rControl),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: filled ? forgeLime : surface,
          borderRadius: BorderRadius.circular(rControl),
          border: Border.all(color: filled ? forgeLime : hairline),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: fg),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: fg,
                fontSize: 11,
                height: 1.1,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KcalHeader extends StatelessWidget {
  const _KcalHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(2, 2, 0, 4),
      child: Text(
        'Ernährung',
        style: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}

class _FoodDateStrip extends StatelessWidget {
  const _FoodDateStrip({
    required this.selectedDate,
    required this.pastDays,
    required this.onSelected,
  });

  final DateTime selectedDate;
  final int pastDays;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final selected = DateUtils.dateOnly(selectedDate);
    final days = List<DateTime>.generate(
      pastDays + 1,
      (index) => today.subtract(Duration(days: pastDays - index)),
    );

    return Container(
      key: const ValueKey('food-date-strip'),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(rCard),
        border: Border.all(color: hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_rounded,
                    size: 15, color: forgeLime),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _selectedLabel(today, selected),
                    key: const ValueKey('food-date-selected-label'),
                    style: const TextStyle(
                      color: textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                const Text(
                  'Verlauf',
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              for (var index = 0; index < days.length; index++) ...[
                Expanded(
                  child: _FoodDateChip(
                    key: ValueKey('food-date-chip-$index'),
                    date: days[index],
                    label: _chipLabel(index, today, days[index]),
                    selected: DateUtils.isSameDay(days[index], selected),
                    onTap: () => onSelected(days[index]),
                  ),
                ),
                if (index != days.length - 1) const SizedBox(width: 6),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static String _chipLabel(int index, DateTime today, DateTime date) {
    final offset = today.difference(date).inDays;
    if (offset == 0) return 'Heute';
    if (offset == 1) return 'Gestern';
    return '${date.day}.${date.month}.';
  }

  static String _selectedLabel(DateTime today, DateTime selected) {
    final offset = today.difference(selected).inDays;
    if (offset == 0) return 'Heute';
    if (offset == 1) return 'Gestern';
    return 'Vor $offset Tagen';
  }
}

class _FoodDateChip extends StatelessWidget {
  const _FoodDateChip({
    super.key,
    required this.date,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final DateTime date;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(rControl),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? forgeLime : surfaceSoft,
          borderRadius: BorderRadius.circular(rControl),
          border: Border.all(
            color: selected ? forgeLime : hairline,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? bg : textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${date.day}.${date.month}.',
              style: TextStyle(
                color: selected ? bg.withValues(alpha: 0.72) : textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

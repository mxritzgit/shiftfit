import 'package:flutter/material.dart';

import '../../models/favorite_meal.dart';
import '../../models/logged_meal.dart';
import '../../models/meal_analysis_result.dart';
import '../../theme/app_colors.dart';
import '../common/basic_widgets.dart';

class FavoritesCard extends StatelessWidget {
  const FavoritesCard({
    super.key,
    required this.favorites,
    required this.onPick,
    required this.onRemove,
    this.recentMeals = const <LoggedMeal>[],
    this.maxRecent = 4,
  });

  final List<FavoriteMeal> favorites;
  final ValueChanged<MealAnalysisResult> onPick;
  final ValueChanged<String> onRemove;

  /// Kürzlich geloggte Mahlzeiten — getrennt von echten Favoriten dargestellt
  /// (cyan-Akzent „Zuletzt"). Default leer → Sektion ausgeblendet, bestehende
  /// Aufrufer bleiben unverändert.
  final List<LoggedMeal> recentMeals;

  /// Wie viele „Zuletzt"-Einträge maximal gezeigt werden.
  final int maxRecent;

  /// Letzte Meals, dedupliziert: pro Name nur der jüngste Eintrag, und
  /// Einträge die bereits als Favorit existieren werden ausgeblendet (keine
  /// Doppelung zwischen den beiden Sektionen).
  List<LoggedMeal> get _dedupedRecents {
    final favoriteIds = favorites.map((f) => f.id).toSet();
    final seen = <String>{};
    final out = <LoggedMeal>[];
    for (final meal in recentMeals) {
      final id = FavoriteMeal.idFor(meal.result);
      if (favoriteIds.contains(id)) continue;
      if (!seen.add(id)) continue;
      out.add(meal);
      if (out.length >= maxRecent) break;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final recents = _dedupedRecents;
    if (favorites.isEmpty && recents.isEmpty) {
      return const SizedBox.shrink();
    }

    return AppCard(
      key: const ValueKey('favorites-card'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recents.isNotEmpty) ...[
            const _SectionHeaderDot(
              title: 'Zuletzt',
              accent: cyan,
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < recents.length; i++) ...[
              _QuickPickTile(
                key: ValueKey('recent-tile-$i'),
                title: recents[i].result.mealName,
                subtitle:
                    '${recents[i].result.caloriesKcal} kcal · ${recents[i].result.estimatedGrams} g',
                icon: Icons.history_rounded,
                accent: cyan,
                onTap: () => onPick(recents[i].result),
              ),
              if (i != recents.length - 1) const SizedBox(height: 8),
            ],
          ],
          if (recents.isNotEmpty && favorites.isNotEmpty)
            const SizedBox(height: 16),
          if (favorites.isNotEmpty) ...[
            const SectionHeader(title: 'Schnellauswahl', action: 'Letzte'),
            const SizedBox(height: 10),
            for (var i = 0; i < favorites.length; i++) ...[
              _FavoriteTile(
                key: ValueKey('favorite-tile-$i'),
                entry: favorites[i],
                onTap: () => onPick(favorites[i].result),
                onRemove: () => onRemove(favorites[i].id),
              ),
              if (i != favorites.length - 1) const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }
}

/// Section-Header mit farbigem Encoding-Punkt (für „Zuletzt" cyan).
class _SectionHeaderDot extends StatelessWidget {
  const _SectionHeaderDot({required this.title, required this.accent});

  final String title;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

/// Schlanke Tap-Zeile für „Zuletzt"-Einträge (ohne Entfernen-Button).
class _QuickPickTile extends StatelessWidget {
  const _QuickPickTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(rControl),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: surfaceSoft,
          borderRadius: BorderRadius.circular(rControl),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(rControl),
              ),
              child: Icon(icon, color: accent, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.add_rounded, color: textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

class _FavoriteTile extends StatelessWidget {
  const _FavoriteTile({
    super.key,
    required this.entry,
    required this.onTap,
    required this.onRemove,
  });

  final FavoriteMeal entry;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(rControl),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
        decoration: BoxDecoration(
          color: surfaceSoft,
          borderRadius: BorderRadius.circular(rControl),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: orange.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(rControl),
              ),
              child: const Icon(
                Icons.bookmark_outline_rounded,
                color: orange,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.result.mealName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${entry.result.caloriesKcal} kcal · ${entry.result.estimatedGrams} g',
                    style: const TextStyle(
                      color: textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onRemove,
              tooltip: 'Entfernen',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close_rounded, color: textMuted, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}

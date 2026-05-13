import 'package:flutter/material.dart';

import '../../models/favorite_meal.dart';
import '../../models/meal_analysis_result.dart';
import '../../theme/app_colors.dart';
import '../common/basic_widgets.dart';

class FavoritesCard extends StatelessWidget {
  const FavoritesCard({
    super.key,
    required this.favorites,
    required this.onPick,
    required this.onRemove,
  });

  final List<FavoriteMeal> favorites;
  final ValueChanged<MealAnalysisResult> onPick;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    if (favorites.isEmpty) {
      return const SizedBox.shrink();
    }

    return AppCard(
      key: const ValueKey('favorites-card'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
        decoration: BoxDecoration(
          color: surfaceSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: orange.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
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

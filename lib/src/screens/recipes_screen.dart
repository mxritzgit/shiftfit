import 'package:flutter/material.dart';

import '../models/fitness_recipe.dart';
import '../models/logged_meal.dart';
import '../models/meal_analysis_result.dart';
import '../theme/app_colors.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({
    super.key,
    required this.onAddMeal,
  });

  final void Function(MealAnalysisResult result, MealSlot slot) onAddMeal;

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  String selectedFilter = 'Alle';
  String query = '';

  List<FitnessRecipe> get filteredRecipes {
    final normalizedQuery = query.trim().toLowerCase();
    return fitnessRecipes.where((recipe) {
      final matchesFilter = selectedFilter == 'Alle' ||
          recipe.categories.contains(selectedFilter);
      final matchesQuery = normalizedQuery.isEmpty ||
          recipe.title.toLowerCase().contains(normalizedQuery) ||
          recipe.description.toLowerCase().contains(normalizedQuery) ||
          recipe.categories.any(
            (category) => category.toLowerCase().contains(normalizedQuery),
          );
      return matchesFilter && matchesQuery;
    }).toList(growable: false);
  }

  void _openRecipe(FitnessRecipe recipe) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RecipeDetailScreen(
          recipe: recipe,
          onAddMeal: widget.onAddMeal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleRecipes = filteredRecipes;
    final recommended = fitnessRecipes.take(4).toList(growable: false);

    return Column(
      key: const ValueKey('screen-recipes'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _RecipesHeader(),
        const SizedBox(height: 18),
        _RecipeSearchField(onChanged: (value) => setState(() => query = value)),
        const SizedBox(height: 16),
        _RecipeFilterChips(
          selected: selectedFilter,
          onSelected: (filter) => setState(() => selectedFilter = filter),
        ),
        const SizedBox(height: 24),
        _SectionHeader(
          title: 'Empfehlungen',
          subtitle: '${fitnessRecipes.length} Fitness-Gerichte',
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 244,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: recommended.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final recipe = recommended[index];
              return _RecipeHeroCard(
                recipe: recipe,
                onTap: () => _openRecipe(recipe),
              );
            },
          ),
        ),
        const SizedBox(height: 26),
        _SectionHeader(
          title: selectedFilter == 'Alle' ? 'Alle Rezepte' : selectedFilter,
          subtitle: '${visibleRecipes.length} Treffer',
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < visibleRecipes.length; i++) ...[
          _RecipeListTile(
            key: ValueKey('recipe-tile-${visibleRecipes[i].slug}'),
            recipe: visibleRecipes[i],
            onTap: () => _openRecipe(visibleRecipes[i]),
          ),
          if (i != visibleRecipes.length - 1) const SizedBox(height: 10),
        ],
        if (visibleRecipes.isEmpty) const _RecipeEmptyState(),
      ],
    );
  }
}

class _RecipesHeader extends StatelessWidget {
  const _RecipesHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rezepte',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Clean Meals mit echten Bildern und Tracker-Werten.',
                style: TextStyle(
                  color: textMuted.withValues(alpha: 0.92),
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: hairline),
          ),
          child: const Icon(Icons.menu_book_rounded, color: lime, size: 21),
        ),
      ],
    );
  }
}

class _RecipeSearchField extends StatelessWidget {
  const _RecipeSearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hairline),
      ),
      child: TextField(
        key: const ValueKey('recipes-search-input'),
        onChanged: onChanged,
        style: const TextStyle(color: textPrimary, fontSize: 14),
        cursorColor: lime,
        decoration: const InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search_rounded, color: textMuted, size: 20),
          hintText: 'Gericht, Ziel oder Kategorie suchen',
          hintStyle: TextStyle(color: textMuted, fontSize: 13),
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _RecipeFilterChips extends StatelessWidget {
  const _RecipeFilterChips({
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: recipeFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = recipeFilters[index];
          final active = selected == filter;
          return InkWell(
            key: ValueKey('recipe-filter-$filter'),
            onTap: () => onSelected(filter),
            borderRadius: BorderRadius.circular(999),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? lime : surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: active ? lime : hairline),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color: active ? bg : textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.35,
            ),
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            color: textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _RecipeHeroCard extends StatelessWidget {
  const _RecipeHeroCard({required this.recipe, required this.onTap});

  final FitnessRecipe recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        width: 198,
        child: Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: hairline),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: 126,
                    width: double.infinity,
                    child: Image.asset(recipe.imageAsset, fit: BoxFit.cover),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.26),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    top: 10,
                    child: _GlassBadge(text: '${recipe.caloriesKcal} kcal'),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textPrimary,
                        fontSize: 15,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      recipe.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textMuted,
                        fontSize: 11.5,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _MacroRow(recipe: recipe, compact: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecipeListTile extends StatelessWidget {
  const _RecipeListTile({
    super.key,
    required this.recipe,
    required this.onTap,
  });

  final FitnessRecipe recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: hairline),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                recipe.imageAsset,
                width: 74,
                height: 74,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: textPrimary,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recipe.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: textMuted,
                      fontSize: 11.5,
                      height: 1.25,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _MacroRow(recipe: recipe),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

class RecipeDetailScreen extends StatelessWidget {
  const RecipeDetailScreen({
    super.key,
    required this.recipe,
    required this.onAddMeal,
  });

  final FitnessRecipe recipe;
  final void Function(MealAnalysisResult result, MealSlot slot) onAddMeal;

  void _add(BuildContext context, MealSlot slot) {
    onAddMeal(recipe.toMealResult(), slot);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${recipe.caloriesKcal} kcal zu ${slot.label} hinzugefügt.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          key: const ValueKey('recipe-detail-scroll'),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _RoundIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  _GlassBadge(text: 'FitPilot Rezept', dark: true),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset(
                  recipe.imageAsset,
                  height: 258,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                recipe.title,
                key: ValueKey('recipe-detail-${recipe.slug}'),
                style: const TextStyle(
                  color: textPrimary,
                  fontSize: 28,
                  height: 1.06,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                recipe.description,
                style: const TextStyle(
                  color: textMuted,
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              _NutritionGrid(recipe: recipe),
              const SizedBox(height: 18),
              _AddToMealCard(onAdd: (slot) => _add(context, slot)),
              const SizedBox(height: 18),
              _RecipeInfoSection(title: 'Portion', body: recipe.portion),
              _RecipeInfoSection(title: 'Zutaten', body: recipe.ingredients),
              _RecipeInfoSection(title: 'Zubereitung', body: recipe.preparation),
              _RecipeInfoSection(
                title: 'Profi-Hinweis',
                body: recipe.professionalHint,
                accent: lime,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddToMealCard extends StatelessWidget {
  const _AddToMealCard({required this.onAdd});

  final ValueChanged<MealSlot> onAdd;

  @override
  Widget build(BuildContext context) {
    const slots = <MealSlot>[
      MealSlot.breakfast,
      MealSlot.lunch,
      MealSlot.dinner,
      MealSlot.snack,
    ];
    return Container(
      key: const ValueKey('recipe-add-card'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Zum Tracker hinzufügen',
            style: TextStyle(
              color: textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Nährwerte fließen direkt in Kalorien und Makros ein.',
            style: TextStyle(color: textMuted, fontSize: 12, height: 1.35),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final slot in slots)
                _MealSlotButton(
                  slot: slot,
                  onTap: () => onAdd(slot),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MealSlotButton extends StatelessWidget {
  const _MealSlotButton({required this.slot, required this.onTap});

  final MealSlot slot;
  final VoidCallback onTap;

  Color get color => switch (slot) {
        MealSlot.breakfast => orange,
        MealSlot.lunch => lime,
        MealSlot.dinner => pink,
        MealSlot.snack => cyan,
      };

  IconData get icon => switch (slot) {
        MealSlot.breakfast => Icons.wb_sunny_outlined,
        MealSlot.lunch => Icons.light_mode_outlined,
        MealSlot.dinner => Icons.nights_stay_outlined,
        MealSlot.snack => Icons.cookie_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey('recipe-add-${slot.name}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.36)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 6),
            Text(
              slot.label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NutritionGrid extends StatelessWidget {
  const _NutritionGrid({required this.recipe});

  final FitnessRecipe recipe;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _NutritionTile(label: 'Kcal', value: '${recipe.caloriesKcal}', color: lime)),
        const SizedBox(width: 8),
        Expanded(child: _NutritionTile(label: 'Protein', value: '${recipe.proteinG} g', color: orange)),
        const SizedBox(width: 8),
        Expanded(child: _NutritionTile(label: 'KH', value: '${recipe.carbsG} g', color: cyan)),
        const SizedBox(width: 8),
        Expanded(child: _NutritionTile(label: 'Fett', value: '${recipe.fatG} g', color: pink)),
      ],
    );
  }
}

class _NutritionTile extends StatelessWidget {
  const _NutritionTile({
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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hairline),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.25,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: textMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipeInfoSection extends StatelessWidget {
  const _RecipeInfoSection({
    required this.title,
    required this.body,
    this.accent = cyan,
  });

  final String title;
  final String body;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              body,
              style: const TextStyle(
                color: textMuted,
                fontSize: 13,
                height: 1.48,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassBadge extends StatelessWidget {
  const _GlassBadge({required this.text, this.dark = false});

  final String text;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: dark ? surface : Colors.black.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  const _MacroRow({required this.recipe, this.compact = false});

  final FitnessRecipe recipe;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final fontSize = compact ? 10.5 : 11.2;
    return Row(
      children: [
        Text(
          '${recipe.proteinG}g P',
          style: TextStyle(color: lime, fontSize: fontSize, fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 8),
        Text(
          '${recipe.carbsG}g KH',
          style: TextStyle(color: textMuted, fontSize: fontSize, fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 8),
        Text(
          '${recipe.fatG}g F',
          style: TextStyle(color: textMuted, fontSize: fontSize, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: hairline),
        ),
        child: Icon(icon, color: textPrimary, size: 20),
      ),
    );
  }
}

class _RecipeEmptyState extends StatelessWidget {
  const _RecipeEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: hairline),
      ),
      child: const Text(
        'Kein Rezept gefunden. Versuch eine andere Kategorie oder Suche.',
        style: TextStyle(color: textMuted, fontSize: 13, height: 1.4),
      ),
    );
  }
}

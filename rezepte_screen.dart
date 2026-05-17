import 'package:flutter/material.dart';

void main() {
  runApp(const RezepteApp());
}

class RezepteApp extends StatelessWidget {
  const RezepteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rezepte',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'SF Pro Display',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF22C55E),
          primary: const Color(0xFF22C55E),
        ),
      ),
      home: const RezepteScreen(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────

class RecipeCategory {
  final String label;
  final IconData icon;
  const RecipeCategory(this.label, this.icon);
}

class Recipe {
  final String title;
  final String description;
  final String duration;
  final int kcal;
  final int protein;
  final int carbs;
  final String tag;
  final Color tagColor;
  final Color imageColor;

  const Recipe({
    required this.title,
    required this.description,
    required this.duration,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.tag,
    required this.tagColor,
    required this.imageColor,
  });
}

class ListRecipe {
  final String title;
  final String description;
  final int kcal;
  final int protein;
  final int carbs;
  final Color imageColor;

  const ListRecipe({
    required this.title,
    required this.description,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.imageColor,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class RezepteScreen extends StatefulWidget {
  const RezepteScreen({super.key});

  @override
  State<RezepteScreen> createState() => _RezepteScreenState();
}

class _RezepteScreenState extends State<RezepteScreen> {
  static const Color kAccent = Color(0xFF22C55E);
  static const Color kInk = Color(0xFF0E1116);
  static const Color kMuted = Color(0xFF6B7280);
  static const Color kSurface = Color(0xFFF3F4F6);
  static const Color kBorder = Color(0xFFE5E7EB);

  int _selectedCategory = 0;
  int _currentNavIndex = 3;

  final List<RecipeCategory> _categories = const [
    RecipeCategory('Alle', Icons.grid_view_rounded),
    RecipeCategory('Frühstück', Icons.wb_sunny_outlined),
    RecipeCategory('Hauptgerichte', Icons.ramen_dining_outlined),
    RecipeCategory('Snacks', Icons.apple_outlined),
    RecipeCategory('Desserts', Icons.cake_outlined),
    RecipeCategory('Getränke', Icons.local_cafe_outlined),
  ];

  final List<Recipe> _recommendations = const [
    Recipe(
      title: 'Hähnchen Bowl',
      description: 'Mit Reis, Brokkoli und\nsüßem Chili-Sesam',
      duration: '25 Min.',
      kcal: 485,
      protein: 38,
      carbs: 52,
      tag: 'High Protein',
      tagColor: Color(0xFF22C55E),
      imageColor: Color(0xFF8B6F47),
    ),
    Recipe(
      title: 'High Protein Pasta',
      description: 'Mit Rinderhack, Tomatensauce\nund Parmesan',
      duration: '20 Min.',
      kcal: 560,
      protein: 42,
      carbs: 61,
      tag: 'High Protein',
      tagColor: Color(0xFF22C55E),
      imageColor: Color(0xFFA0522D),
    ),
    Recipe(
      title: 'Protein Pancakes',
      description: 'Mit Banane, Beeren\nund Ahornsirup',
      duration: '15 Min.',
      kcal: 390,
      protein: 28,
      carbs: 48,
      tag: 'Vegetarisch',
      tagColor: Color(0xFF22C55E),
      imageColor: Color(0xFFD4A574),
    ),
  ];

  final List<ListRecipe> _popular = const [
    ListRecipe(
      title: 'Lachs mit Ofengemüse',
      description: 'Mit Süßkartoffeln, Zucchini und Paprika',
      kcal: 620,
      protein: 44,
      carbs: 58,
      imageColor: Color(0xFFE89A6A),
    ),
    ListRecipe(
      title: 'Hähnchen Wraps',
      description: 'Mit Avocado, Salat und Joghurt-Dip',
      kcal: 450,
      protein: 36,
      carbs: 48,
      imageColor: Color(0xFFC8B68A),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildSearchBar(),
                    const SizedBox(height: 22),
                    _buildCategoryChips(),
                    const SizedBox(height: 28),
                    _buildSectionHeader('Empfehlungen'),
                    const SizedBox(height: 14),
                    _buildRecommendations(),
                    const SizedBox(height: 28),
                    _buildSectionHeader('Beliebt'),
                    const SizedBox(height: 14),
                    _buildPopularList(),
                  ],
                ),
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Rezepte',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: kInk,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.eco_outlined, color: kAccent, size: 26),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Entdecke leckere, gesunde Rezepte\nfür deine Ziele.',
                  style: TextStyle(
                    fontSize: 14,
                    color: kMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: kBorder),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.tune, color: kInk, size: 20),
          ),
        ],
      ),
    );
  }

  // ── Search bar ────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          children: [
            SizedBox(width: 18),
            Icon(Icons.search, color: kMuted, size: 22),
            SizedBox(width: 12),
            Text(
              'Rezepte suchen...',
              style: TextStyle(color: kMuted, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  // ── Category chips ────────────────────────────────────────────────────────
  Widget _buildCategoryChips() {
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final selected = index == _selectedCategory;
          final cat = _categories[index];
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = index),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 52,
                  decoration: BoxDecoration(
                    color: selected ? kInk : Colors.white,
                    border: Border.all(
                      color: selected ? kInk : kBorder,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    cat.icon,
                    color: selected ? kAccent : kInk,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  cat.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? kInk : kMuted,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Section header ────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: kInk,
              letterSpacing: -0.3,
            ),
          ),
          Row(
            children: [
              Text(
                'Alle anzeigen',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kAccent,
                ),
              ),
              Icon(Icons.chevron_right, color: kAccent, size: 18),
            ],
          ),
        ],
      ),
    );
  }

  // ── Recommendations row (horizontal cards) ────────────────────────────────
  Widget _buildRecommendations() {
    return SizedBox(
      height: 280,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _recommendations.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          return _RecipeCard(recipe: _recommendations[index]);
        },
      ),
    );
  }

  // ── Popular list (vertical list items) ────────────────────────────────────
  Widget _buildPopularList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(_popular.length, (i) {
          return Padding(
            padding: EdgeInsets.only(bottom: i == _popular.length - 1 ? 0 : 14),
            child: _PopularItem(recipe: _popular[i]),
          );
        }),
      ),
    );
  }

  // ── Bottom navigation ─────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    final items = [
      _NavItem('Dashboard', Icons.dashboard_outlined),
      _NavItem('Workouts', Icons.fitness_center_outlined),
      _NavItem('Ernährung', Icons.restaurant_outlined),
      _NavItem('Rezepte', Icons.menu_book_outlined),
      _NavItem('Profil', Icons.person_outline),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: kBorder, width: 0.8)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final active = i == _currentNavIndex;
          final item = items[i];
          return GestureDetector(
            onTap: () => setState(() => _currentNavIndex = i),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.icon,
                    color: active ? kAccent : kMuted,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active ? kAccent : kMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  const _NavItem(this.label, this.icon);
}

// ─────────────────────────────────────────────────────────────────────────────
// Recipe card (horizontal scroll)
// ─────────────────────────────────────────────────────────────────────────────

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  const _RecipeCard({required this.recipe});

  static const Color kInk = Color(0xFF0E1116);
  static const Color kMuted = Color(0xFF6B7280);
  static const Color kAccent = Color(0xFF22C55E);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image area
          Stack(
            children: [
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: recipe.imageColor.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      recipe.imageColor.withOpacity(0.55),
                      recipe.imageColor.withOpacity(0.25),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.restaurant,
                    color: Colors.white.withOpacity(0.5),
                    size: 40,
                  ),
                ),
              ),
              // Duration badge
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time,
                          color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        recipe.duration,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Bookmark
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bookmark_border,
                      color: kInk, size: 16),
                ),
              ),
              // Tag
              Positioned(
                bottom: 10,
                left: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: recipe.tagColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    recipe.tag,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            recipe.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: kInk,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            recipe.description,
            style: const TextStyle(
              fontSize: 12,
              color: kMuted,
              height: 1.35,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('${recipe.kcal} kcal',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: kAccent,
                  )),
              const SizedBox(width: 8),
              Text('${recipe.protein}g Protein',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: kMuted,
                  )),
              const SizedBox(width: 8),
              Text('${recipe.carbs}g KH',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: kMuted,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Popular list item
// ─────────────────────────────────────────────────────────────────────────────

class _PopularItem extends StatelessWidget {
  final ListRecipe recipe;
  const _PopularItem({required this.recipe});

  static const Color kInk = Color(0xFF0E1116);
  static const Color kMuted = Color(0xFF6B7280);
  static const Color kAccent = Color(0xFF22C55E);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                recipe.imageColor.withOpacity(0.6),
                recipe.imageColor.withOpacity(0.3),
              ],
            ),
          ),
          child: Center(
            child: Icon(
              Icons.restaurant,
              color: Colors.white.withOpacity(0.6),
              size: 26,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recipe.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kInk,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                recipe.description,
                style: const TextStyle(
                  fontSize: 12,
                  color: kMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text('${recipe.kcal} kcal',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: kAccent,
                      )),
                  const SizedBox(width: 8),
                  Text('${recipe.protein}g Protein',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: kMuted,
                      )),
                  const SizedBox(width: 8),
                  Text('${recipe.carbs}g KH',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: kMuted,
                      )),
                ],
              ),
            ],
          ),
        ),
        const Icon(Icons.bookmark_border, color: kInk, size: 22),
      ],
    );
  }
}

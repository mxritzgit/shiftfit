part of 'meal_widgets.dart';

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
              borderRadius: BorderRadius.circular(rCard),
            ),
            child: imageBytes == null
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.restaurant_menu_outlined,
                        color: textMuted,
                        size: 32,
                      ),
                      SizedBox(height: 8),
                      Text(
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
              borderRadius: BorderRadius.circular(rControl),
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
                    fontFeatures: [FontFeature.tabularFigures()],
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
              borderRadius: BorderRadius.circular(rControl),
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
                  borderRadius: BorderRadius.circular(rControl),
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
            borderRadius: BorderRadius.circular(rPill),
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

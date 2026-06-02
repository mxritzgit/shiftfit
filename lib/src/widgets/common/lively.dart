import 'package:flutter/material.dart';

/// Subtiler Auftritts-Effekt: sanftes Einblenden + leichtes Hochgleiten, wenn
/// ein Inhalt erscheint. Bewusst dezent (keine „krassen" Animationen) — gibt
/// den ansonsten statischen Seiten etwas Leben.
///
/// Das Kind bleibt immer im Widget-Baum (nur [Opacity]/[Transform] ändern sich),
/// damit Hit-Testing, Keys und Widget-Tests unberührt bleiben. Über einen
/// wechselnden [key] (z.B. pro Tab) spielt der Auftritt erneut ab.
class LivelyEntrance extends StatefulWidget {
  const LivelyEntrance({
    super.key,
    required this.child,
    this.offsetY = 10,
    this.duration = const Duration(milliseconds: 320),
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final double offsetY;
  final Duration duration;
  final Curve curve;

  @override
  State<LivelyEntrance> createState() => _LivelyEntranceState();
}

class _LivelyEntranceState extends State<LivelyEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _anim = CurvedAnimation(parent: _controller, curve: widget.curve);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A11y: "Bewegung reduzieren" respektieren — den Auftritt überspringen und
    // den Inhalt sofort statisch zeigen (kein Fade/Slide).
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      return widget.child;
    }
    // FadeTransition statt eines roh animierten Opacity-Widgets: Letzteres
    // erzwingt pro Frame ein saveLayer (Offscreen-Rasterung der GANZEN Seite)
    // — 60x/s ueber die Auftrittsdauer, bei jedem Tab-Wechsel. FadeTransition
    // nutzt die guenstige Opacity-Layer-Pipeline und baut das Kind nicht neu.
    // Das Kind steckt in einer RepaintBoundary: die Seite wird einmal
    // gerastert, der Auftritt komponiert nur den fertigen Layer neu statt ihn
    // jeden Frame neu zu zeichnen. Der leichte Hochgleit-Effekt bleibt ein
    // reiner Transform-Layer (billig, kein Re-Raster).
    return FadeTransition(
      opacity: _anim,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, (1 - _anim.value) * widget.offsetY),
            child: child,
          );
        },
        child: RepaintBoundary(child: widget.child),
      ),
    );
  }
}

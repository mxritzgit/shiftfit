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
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        final t = _anim.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * widget.offsetY),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

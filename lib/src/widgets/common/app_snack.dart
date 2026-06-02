import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Standard-Toast-Dauern — bewusst kurz, damit nichts „hängen bleibt".
const Duration kSnackShort = Duration(milliseconds: 1600); // einfache Bestätigung
const Duration kSnackAction = Duration(milliseconds: 2200); // mit Aktion (Undo) —
// kurz genug, dass der Toast klar von selbst verschwindet, lang genug um die
// „Rückgängig"-Aktion noch zu treffen.
const Duration kSnackError = Duration(milliseconds: 3000);

/// Zeigt einen kurzen, floating Toast. Entfernt IMMER zuerst den aktuellen
/// Toast, damit sich Snackbars bei schnellen Aktionen NICHT stapeln. Optionales
/// Leading-Icon poppt beim Erscheinen kurz auf (kleine Animation), optionale
/// [action] (z. B. Undo).
///
/// Auto-Dismiss: Flutters eingebauter Snackbar-Timer feuert NICHT zuverlässig,
/// wenn die System-Animation aus ist („Bewegung reduzieren") — dann schließt die
/// Entrance synchron ab und der Timer wird nie gestartet, die Snackbar bleibt
/// stehen. Wir hängen deshalb einen eigenen Dismiss-Timer an den Lifecycle des
/// Snackbar-Inhalts ([_AutoDismiss]): er greift unabhängig von der Animation-
/// Einstellung und wird bei Widget-Dispose sauber abgeräumt (kein dangling Timer
/// in Tests).
void showAppSnack(
  BuildContext context,
  String message, {
  IconData? icon,
  Color accent = lime,
  SnackBarAction? action,
  Duration? duration,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger.removeCurrentSnackBar();
  final effective = duration ?? (action != null ? kSnackAction : kSnackShort);
  messenger.showSnackBar(
    SnackBar(
      duration: effective,
      content: _AutoDismiss(
        duration: effective,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              _SnackIcon(icon: icon, accent: accent),
              const SizedBox(width: 10),
            ],
            Flexible(child: Text(message)),
          ],
        ),
      ),
      action: action,
    ),
  );
}

/// Hängt einen Dismiss-Timer an den Snackbar-Inhalt. Greift auch dann, wenn der
/// eingebaute Auto-Dismiss ausbleibt (Animation aus). Da der Timer am State des
/// Snackbar-Inhalts hängt, wird er bei Dispose (Snackbar weg / von neuer ersetzt
/// / Test-Teardown) automatisch gecancelt — daher kein hängender Timer in Tests.
class _AutoDismiss extends StatefulWidget {
  const _AutoDismiss({required this.child, required this.duration});

  final Widget child;
  final Duration duration;

  @override
  State<_AutoDismiss> createState() => _AutoDismissState();
}

class _AutoDismissState extends State<_AutoDismiss> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Etwas nach der Snackbar-Dauer: lässt dem eingebauten Timer den Vortritt,
    // springt aber ein, wenn der ausbleibt.
    _timer = Timer(
      widget.duration + const Duration(milliseconds: 400),
      () {
        // removeCurrentSnackBar (statt hideCurrentSnackBar): entfernt SOFORT
        // ohne Exit-Animation -> auch dann garantiert weg, wenn Animationen
        // aus/kaputt sind. Greift nur wenn diese Snackbar noch aktuell ist
        // (sonst ist dieses Widget längst disposed + der Timer gecancelt).
        if (mounted) {
          ScaffoldMessenger.maybeOf(context)?.removeCurrentSnackBar(
            reason: SnackBarClosedReason.timeout,
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Kleines, beim Erscheinen kurz aufpoppendes Icon (easeOutBack-Scale).
class _SnackIcon extends StatelessWidget {
  const _SnackIcon({required this.icon, required this.accent});

  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.5, end: 1.0),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Transform.scale(scale: t, child: child),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 15, color: accent),
      ),
    );
  }
}

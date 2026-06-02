import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Standard-Toast-Dauern — bewusst kurz, damit nichts „hängen bleibt".
const Duration kSnackShort = Duration(milliseconds: 1600); // einfache Bestätigung
const Duration kSnackAction = Duration(milliseconds: 2200); // mit Aktion (Undo) —
// kurz genug, dass der Toast klar von selbst verschwindet, lang genug um die
// „Rückgängig"-Aktion noch zu treffen.
const Duration kSnackError = Duration(milliseconds: 3000);

/// Zeigt einen kurzen, floating Toast. Entfernt IMMER zuerst den aktuellen
/// Toast, damit sich Snackbars bei schnellen Aktionen NICHT stapeln — das war
/// die Ursache für „bleibt 20–30 s sichtbar / geht nicht weg" (jeder ungekürzte
/// Default-Toast hängte 4 s in der Queue). Optionales Leading-Icon poppt beim
/// Erscheinen kurz auf (kleine Animation), optionale [action] (z. B. Undo).
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
  final controller = messenger.showSnackBar(
    SnackBar(
      duration: effective,
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            _SnackIcon(icon: icon, accent: accent),
            const SizedBox(width: 10),
          ],
          Flexible(child: Text(message)),
        ],
      ),
      action: action,
    ),
  );

  // Safety-Net NUR bei deaktivierter System-Animation („Bewegung reduzieren"):
  // dann schließt die Snackbar-Entrance synchron ab und Flutters eingebauter
  // Auto-Dismiss-Timer feuert teils NICHT → die Snackbar bleibt bis zum
  // manuellen Wegwischen stehen. Wir schließen sie daher selbst nach Ablauf der
  // Dauer (sofern nicht schon weg). Bei aktiver Animation übernimmt der
  // eingebaute Timer (der bei Widget-Dispose sauber abgeräumt wird) — wichtig,
  // damit kein freier Timer in Widget-Tests hängen bleibt.
  if (WidgetsBinding.instance.accessibilityFeatures.disableAnimations) {
    var closed = false;
    controller.closed.then((_) => closed = true);
    Future<void>.delayed(effective + const Duration(milliseconds: 350), () {
      if (!closed) controller.close();
    });
  }
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

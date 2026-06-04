import 'package:flutter/widgets.dart';

/// A11y-Helfer fuer "Bewegung reduzieren" (iOS/Android System-Toggle).
///
/// Liefert die uebergebene Dauer normal zurueck — aber `Duration.zero`, wenn
/// der Nutzer im System reduzierte Bewegung aktiviert hat. So kollabieren
/// Intro-Gates und Deko-Animationen sofort, ohne den Happy-Path zu aendern,
/// solange der Toggle aus ist.
Duration motionDuration(BuildContext context, Duration base) {
  final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  return reduce ? Duration.zero : base;
}

/// Wie [motionDuration], aber fuer eine optionale Pause (z.B. eine
/// `Future.delayed`-Haltezeit). Unter reduzierter Bewegung -> `Duration.zero`.
Duration motionDelay(BuildContext context, Duration base) =>
    motionDuration(context, base);

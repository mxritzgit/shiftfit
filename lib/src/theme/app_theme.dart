import 'package:flutter/material.dart';

import 'app_colors.dart';

ThemeData buildShiftFitTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: lime,
      brightness: Brightness.dark,
      surface: surface,
      primary: lime,
    ),
    scaffoldBackgroundColor: bg,
    fontFamily: 'Roboto',
  );

  return base.copyWith(
    textTheme: base.textTheme
        .apply(bodyColor: textPrimary, displayColor: textPrimary)
        .copyWith(
          bodyMedium: const TextStyle(
            color: textPrimary,
            fontSize: 14,
            height: 1.4,
          ),
          bodySmall: const TextStyle(color: textMuted, fontSize: 13, height: 1.4),
        ),
    dividerColor: hairline,
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(rCard),
        side: const BorderSide(color: hairline),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: surfaceSoft,
      contentTextStyle: const TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rCard)),
      behavior: SnackBarBehavior.floating,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceSoft,
      hintStyle: const TextStyle(color: textMuted),
      labelStyle: const TextStyle(color: textMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(rControl),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(rControl),
        borderSide: const BorderSide(color: hairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(rControl),
        borderSide: const BorderSide(color: lime),
      ),
    ),
  );
}

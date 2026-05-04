import 'package:flutter/material.dart';

import 'app_colors.dart';

ThemeData buildShiftFitTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: lime,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: bg,
    snackBarTheme: SnackBarThemeData(
      backgroundColor: surfaceSoft,
      contentTextStyle: const TextStyle(fontWeight: FontWeight.w700),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      behavior: SnackBarBehavior.floating,
    ),
    useMaterial3: true,
  );
}

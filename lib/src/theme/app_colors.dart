import 'package:flutter/material.dart';

const Color bg = Color(0xFF080B10);
const Color surface = Color(0xFF111927);
const Color surfaceSoft = Color(0xFF172233);
const Color lime = Color(0xFF9BFF67);
const Color cyan = Color(0xFF63D8FF);
const Color orange = Color(0xFFFFC266);
const Color pink = Color(0xFFFF7DB8);

Color shiftColor(String shift) {
  return switch (shift) {
    'Früh' => lime,
    'Spät' => orange,
    'Nacht' => pink,
    'Frei' => cyan,
    _ => Colors.white,
  };
}

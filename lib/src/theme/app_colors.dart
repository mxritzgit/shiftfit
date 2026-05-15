import 'package:flutter/material.dart';

const Color bg = Color(0xFF0B0D11);
const Color surface = Color(0xFF14171D);
const Color surfaceSoft = Color(0xFF1B1F27);

const Color lime = Color(0xFFB6F36A);
const Color violet = Color(0xFF8B5CF6);
const Color deepViolet = Color(0xFF4C1D95);
const Color cyan = Color(0xFF7DD3FC);
const Color orange = Color(0xFFFDBA74);
const Color pink = Color(0xFFF9A8D4);

const Color textPrimary = Color(0xFFF5F6F8);
const Color textMuted = Color(0xFF8A8F99);
const Color hairline = Color(0x1AFFFFFF);

Color shiftColor(String shift) {
  return switch (shift) {
    'Kraft' => lime,
    'Muskelaufbau' => lime,
    'Ausdauer' => orange,
    'Mobility' => cyan,
    'Recovery' => cyan,
    'Frei' => cyan,
    _ => textPrimary,
  };
}

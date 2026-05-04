import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'shiftfit_home_page.dart';

class ShiftFitApp extends StatelessWidget {
  const ShiftFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ShiftFit',
      theme: buildShiftFitTheme(),
      home: const ShiftFitHomePage(),
    );
  }
}

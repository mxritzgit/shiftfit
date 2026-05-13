import 'package:flutter/material.dart';

import '../services/health_service.dart';
import '../services/meal_analyzer.dart';
import '../services/meal_photo_input.dart';
import '../services/open_food_facts_product_service.dart';
import '../theme/app_theme.dart';
import 'shiftfit_home_page.dart';

class ShiftFitApp extends StatelessWidget {
  const ShiftFitApp({
    super.key,
    this.mealAnalyzer,
    this.productService,
    this.photoInput,
    this.healthService,
  });

  final MealAnalyzer? mealAnalyzer;
  final ProductLookupService? productService;
  final MealPhotoInput? photoInput;
  final HealthService? healthService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ShiftFit',
      theme: buildShiftFitTheme(),
      home: ShiftFitHomePage(
        mealAnalyzer: mealAnalyzer,
        productService: productService,
        photoInput: photoInput,
        healthService: healthService,
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../auth/auth_repository.dart';
import '../services/health_service.dart';
import '../services/meal_analyzer.dart';
import '../services/meal_photo_input.dart';
import '../services/open_food_facts_product_service.dart';
import '../theme/app_theme.dart';
import 'auth_gate.dart';
import 'shiftfit_home_page.dart';

class ShiftFitApp extends StatelessWidget {
  const ShiftFitApp({
    super.key,
    this.mealAnalyzer,
    this.productService,
    this.photoInput,
    this.healthService,
    this.authRepository,
  });

  final MealAnalyzer? mealAnalyzer;
  final ProductLookupService? productService;
  final MealPhotoInput? photoInput;
  final HealthService? healthService;
  final AuthRepository? authRepository;

  @override
  Widget build(BuildContext context) {
    final repository = authRepository ?? defaultAuthRepository();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FitPilot',
      theme: buildShiftFitTheme(),
      home: AuthGate(
        authRepository: repository,
        builder: (context, user) => ShiftFitHomePage(
          mealAnalyzer: mealAnalyzer,
          productService: productService,
          photoInput: photoInput,
          healthService: healthService,
          initialUserName: user.firstName,
          onSignOut: repository.signOut,
        ),
      ),
    );
  }
}

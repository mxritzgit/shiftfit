import 'package:flutter/material.dart';

import 'src/app/shiftfit_app.dart';
import 'src/services/apple_health_service.dart';

export 'src/app/shiftfit_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ShiftFitApp(healthService: AppleHealthService()));
}

import 'package:flutter/material.dart';

import 'src/app/shiftfit_app.dart';
import 'src/config/supabase_config.dart';
import 'src/services/apple_health_service.dart';

export 'src/app/shiftfit_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FitPilotSupabaseConfig.initialize();
  runApp(ShiftFitApp(healthService: AppleHealthService()));
}

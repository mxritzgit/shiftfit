import 'package:supabase_flutter/supabase_flutter.dart';

import 'daily_log_sync.dart';
import 'meals_sync.dart';
import 'profile_sync.dart';
import 'tracking_sync.dart';

/// Bundles alle Supabase-Sync-Services fuer einen einzelnen authentifizierten
/// User. Wird in ShiftFitApp pro User aufgebaut, an die HomePage uebergeben
/// und beim Dispose der Page wieder freigegeben.
class FitPilotSync {
  FitPilotSync._({
    required this.profile,
    required this.meals,
    required this.dailyLog,
    required this.tracking,
  });

  factory FitPilotSync.forUser(SupabaseClient client, String userId) {
    return FitPilotSync._(
      profile: ProfileSync(client, userId),
      meals: MealsSync(client, userId),
      dailyLog: DailyLogSync(client, userId),
      tracking: TrackingSync(client, userId),
    );
  }

  final ProfileSync profile;
  final MealsSync meals;
  final DailyLogSync dailyLog;
  final TrackingSync tracking;

  void dispose() {
    dailyLog.dispose();
  }
}

import 'dart:developer' as dev;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/lifetime_stats.dart';

/// Liest und schreibt LifetimeStats gegen public.lifetime_stats. Genau eine
/// Zeile pro User (primary key user_id). Die Zeile wird beim User-Anlegen
/// per Bootstrap-Trigger erzeugt; save() nutzt dennoch upsert(onConflict
/// user_id), damit ein fehlender Bootstrap (Alt-Account) selbstheilt.
class LifetimeStatsSync {
  LifetimeStatsSync(this._client, this._userId);

  final SupabaseClient _client;
  final String _userId;

  Future<LifetimeStats?> load() async {
    try {
      final row = await _client
          .from('lifetime_stats')
          .select(
              'workouts_completed, meals_logged, water_total_ml, steps_recorded, weight_logs, current_streak, longest_streak, last_workout_date, session_start')
          .eq('user_id', _userId)
          .maybeSingle();
      if (row == null) {
        dev.log('LifetimeStatsSync.load: no row for $_userId',
            name: 'lifetime_stats_sync');
        return null;
      }
      return LifetimeStats.fromRow(row);
    } catch (e, stack) {
      dev.log('LifetimeStatsSync.load failed',
          error: e, stackTrace: stack, name: 'lifetime_stats_sync');
      rethrow;
    }
  }

  Future<void> save(LifetimeStats stats) async {
    try {
      await _client.from('lifetime_stats').upsert(
        <String, dynamic>{
          'user_id': _userId,
          ...stats.toRow(),
        },
        onConflict: 'user_id',
      );
    } catch (e, stack) {
      dev.log('LifetimeStatsSync.save failed',
          error: e, stackTrace: stack, name: 'lifetime_stats_sync');
      rethrow;
    }
  }
}

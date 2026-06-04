import 'dart:developer' as dev;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/lifetime_stats.dart';

/// Liest und schreibt LifetimeStats gegen public.lifetime_stats. Genau eine
/// Zeile pro User (primary key user_id). Die Zeile wird beim User-Anlegen
/// per Bootstrap-Trigger erzeugt.
///
/// Schreibpfad seit Audit 2026-06-04: KEIN absolutes read-modify-write-Upsert
/// mehr (das verlor bei parallelen Geraeten/Tabs Increments via last-write-
/// wins). Stattdessen serverseitig-atomare RPCs:
///   * increment_lifetime_stats(p_water,p_steps,p_meals,p_weight_logs,
///     p_workouts) — addiert die uebergebenen Deltas atomar (col = col + p_x)
///     und gibt die frische Zeile zurueck.
///   * record_workout_day(p_day) — fuehrt die Streak persistent fort (liest
///     last_workout_date aus der DB statt aus In-Memory) und zaehlt dabei
///     workouts_completed selbst +1 hoch. Gibt die frische Zeile zurueck.
/// Siehe Migration 20260604120000_lifetime_increment_rpcs.sql.
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

  /// Zaehlt die uebergebenen Deltas serverseitig-atomar hoch und liefert die
  /// frische public.lifetime_stats-Zeile zurueck. Nur die gesetzten Felder
  /// (water/steps/meals/weightLogs) werden addiert; die uebrigen RPC-Parameter
  /// defaulten serverseitig auf 0. workouts wird bewusst NICHT hier
  /// hochgezaehlt — dafuer ist [recordWorkoutDay] zustaendig (zaehlt
  /// workouts_completed zusammen mit der Streak in EINEM atomaren Call hoch).
  ///
  /// Negative oder 0-Deltas sind erlaubt (Server clampt mit greatest(x,0));
  /// ein leeres bzw. komplett-0 Delta ist ein No-op-Call, der einfach die
  /// aktuelle Zeile zurueckliefert.
  Future<LifetimeStats> increment({
    int water = 0,
    int steps = 0,
    int meals = 0,
    int weightLogs = 0,
  }) async {
    try {
      final row = await _client.rpc(
        'increment_lifetime_stats',
        params: <String, dynamic>{
          'p_water': water,
          'p_steps': steps,
          'p_meals': meals,
          'p_weight_logs': weightLogs,
        },
      ).select().single();
      return LifetimeStats.fromRow(row);
    } catch (e, stack) {
      dev.log('LifetimeStatsSync.increment failed',
          error: e, stackTrace: stack, name: 'lifetime_stats_sync');
      rethrow;
    }
  }

  /// Verbucht einen abgeschlossenen Workout-Tag serverseitig: schreibt die
  /// Streak (current/longest/last_workout_date) persistent fort UND zaehlt
  /// workouts_completed +1 (im idempotenten „heute schon gezaehlt"-Fall passiert
  /// nichts). Gibt die frische Zeile zurueck — current_streak/longest_streak/
  /// last_workout_date sind jetzt Server-Wahrheit.
  Future<LifetimeStats> recordWorkoutDay(DateTime day) async {
    try {
      final row = await _client.rpc(
        'record_workout_day',
        params: <String, dynamic>{'p_day': _dateOnly(day)},
      ).select().single();
      return LifetimeStats.fromRow(row);
    } catch (e, stack) {
      dev.log('LifetimeStatsSync.recordWorkoutDay failed',
          error: e, stackTrace: stack, name: 'lifetime_stats_sync');
      rethrow;
    }
  }

  static String _dateOnly(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}

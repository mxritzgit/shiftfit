import 'dart:developer' as dev;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/workout_set.dart';

/// Liest und schreibt geloggte Arbeitssaetze gegen public.workout_sets
/// (PROD-5). Spiegelt MealsSync/UserRecipesSync: eine Instanz gehoert einem
/// user_id, jede Methode ist atomar gegen die Tabelle. Insert ist ein
/// idempotenter Upsert auf der Client-UUID (onConflict: 'id') — genau wie
/// MealsSync.insertLoggedMeal, damit ein Retry nach einem verlorenen
/// Netzwerk-Response keinen Duplikat-Fehler erzeugt.
class WorkoutLogSync {
  WorkoutLogSync(this._client, this._userId);

  final SupabaseClient _client;
  final String _userId;

  static const _columns =
      'id, exercise, weight_kg, reps, rpe, logged_at, local_day';

  /// Laedt die juengsten Saetze des Users (neueste zuerst). [limit] begrenzt
  /// die Boot-Load-Groesse, damit die Historie nicht unbegrenzt waechst.
  Future<List<WorkoutSet>> loadRecent({int limit = 200}) async {
    try {
      final rows = await _client
          .from('workout_sets')
          .select(_columns)
          .eq('user_id', _userId)
          .order('logged_at', ascending: false)
          .limit(limit);
      return rows
          .map<WorkoutSet>(
            (row) => WorkoutSet.fromRow((row as Map).cast<String, dynamic>()),
          )
          .toList();
    } catch (e, stack) {
      dev.log('WorkoutLogSync.loadRecent failed',
          error: e, stackTrace: stack, name: 'workout_log_sync');
      rethrow;
    }
  }

  /// Laedt alle Saetze eines lokalen Tages (`YYYY-MM-DD`), neueste zuerst.
  Future<List<WorkoutSet>> loadByLocalDay(String localDay) async {
    try {
      final rows = await _client
          .from('workout_sets')
          .select(_columns)
          .eq('user_id', _userId)
          .eq('local_day', localDay)
          .order('logged_at', ascending: false);
      return rows
          .map<WorkoutSet>(
            (row) => WorkoutSet.fromRow((row as Map).cast<String, dynamic>()),
          )
          .toList();
    } catch (e, stack) {
      dev.log('WorkoutLogSync.loadByLocalDay failed',
          error: e, stackTrace: stack, name: 'workout_log_sync');
      rethrow;
    }
  }

  /// Idempotenter Upsert eines Satzes auf der Client-UUID.
  Future<void> insert(WorkoutSet set) async {
    try {
      await _client.from('workout_sets').upsert({
        'user_id': _userId,
        ...set.toRow(),
      }, onConflict: 'id', ignoreDuplicates: false);
    } catch (e, stack) {
      dev.log('WorkoutLogSync.insert failed',
          error: e, stackTrace: stack, name: 'workout_log_sync');
      rethrow;
    }
  }

  /// Loescht einen Satz (gefiltert auf id + user_id, RLS-konform).
  Future<void> delete(String id) async {
    try {
      await _client
          .from('workout_sets')
          .delete()
          .eq('id', id)
          .eq('user_id', _userId);
    } catch (e, stack) {
      dev.log('WorkoutLogSync.delete failed',
          error: e, stackTrace: stack, name: 'workout_log_sync');
      rethrow;
    }
  }
}

import 'dart:developer' as dev;

import 'package:supabase_flutter/supabase_flutter.dart';

/// Persistiert den 7-Tage-Wochenplan (Liste von Shift-Labels, Index 0=Mo..
/// 6=So) gegen public.weekly_plans. Genau eine Zeile pro User
/// (primary key user_id). Frueher war der Wochenplan rein in-memory und
/// ging bei jedem App-Neustart verloren.
class WeeklyPlanSync {
  WeeklyPlanSync(this._client, this._userId);

  final SupabaseClient _client;
  final String _userId;

  /// Liefert die gespeicherten Tage oder null, wenn noch keine Zeile
  /// existiert (dann behaelt der Aufrufer seinen Default-Plan).
  Future<List<String>?> load() async {
    try {
      final row = await _client
          .from('weekly_plans')
          .select('days')
          .eq('user_id', _userId)
          .maybeSingle();
      if (row == null) return null;
      final raw = row['days'];
      if (raw is List) {
        return raw.map((e) => e.toString()).toList();
      }
      return null;
    } catch (e, stack) {
      dev.log('WeeklyPlanSync.load failed',
          error: e, stackTrace: stack, name: 'weekly_plan_sync');
      rethrow;
    }
  }

  Future<void> save(List<String> days) async {
    try {
      await _client.from('weekly_plans').upsert(
        <String, dynamic>{
          'user_id': _userId,
          'days': days,
        },
        onConflict: 'user_id',
      );
    } catch (e, stack) {
      dev.log('WeeklyPlanSync.save failed',
          error: e, stackTrace: stack, name: 'weekly_plan_sync');
      rethrow;
    }
  }
}

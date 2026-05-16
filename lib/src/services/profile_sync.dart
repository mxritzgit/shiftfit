import 'dart:developer' as dev;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';

/// Liest und schreibt UserProfile gegen public.profiles auf Supabase.
/// Save nutzt UPSERT(.select().single()), damit der Aufrufer bei
/// Schema/Auth/RLS-Fehlern eine PostgrestException kriegt statt einer
/// stillen No-Op. Eine Instanz gehoert genau einem auth.users.id.
class ProfileSync {
  ProfileSync(this._client, this._userId);

  final SupabaseClient _client;
  final String _userId;

  static const _columns =
      'weight_kg, height_cm, age_years, sex, '
      'daily_steps_goal, daily_kcal_goal, daily_water_goal_ml, '
      'daily_sleep_goal_minutes, '
      'protein_goal_g, carbs_goal_g, fat_goal_g';

  Future<UserProfile?> load() async {
    try {
      final row = await _client
          .from('profiles')
          .select(_columns)
          .eq('id', _userId)
          .maybeSingle();
      if (row == null) {
        dev.log('ProfileSync.load: no row for $_userId', name: 'profile_sync');
        return null;
      }
      return UserProfile(
        weightKg: _toInt(row['weight_kg']) ?? 78,
        heightCm: _toInt(row['height_cm']) ?? 178,
        ageYears: _toInt(row['age_years']) ?? 30,
        sex: _parseSex(row['sex']?.toString()),
        dailyStepsGoal: _toInt(row['daily_steps_goal']) ?? 8000,
        dailyKcalGoal: _toInt(row['daily_kcal_goal']) ?? 2200,
        dailyWaterGoalMl: _toInt(row['daily_water_goal_ml']) ?? 2500,
        dailySleepGoalMinutes:
            _toInt(row['daily_sleep_goal_minutes']) ?? 7 * 60 + 30,
        proteinGoalG: _toInt(row['protein_goal_g']) ?? 130,
        carbsGoalG: _toInt(row['carbs_goal_g']) ?? 240,
        fatGoalG: _toInt(row['fat_goal_g']) ?? 70,
      );
    } catch (e, stack) {
      dev.log('ProfileSync.load failed', error: e, stackTrace: stack, name: 'profile_sync');
      rethrow;
    }
  }

  Future<void> save(UserProfile profile) async {
    final payload = <String, dynamic>{
      'id': _userId,
      'weight_kg': profile.weightKg,
      'height_cm': profile.heightCm,
      'age_years': profile.ageYears,
      'sex': profile.sex.name,
      'daily_steps_goal': profile.dailyStepsGoal,
      'daily_kcal_goal': profile.dailyKcalGoal,
      'daily_water_goal_ml': profile.dailyWaterGoalMl,
      'daily_sleep_goal_minutes': profile.dailySleepGoalMinutes,
      'protein_goal_g': profile.proteinGoalG,
      'carbs_goal_g': profile.carbsGoalG,
      'fat_goal_g': profile.fatGoalG,
    };
    try {
      // UPSERT statt UPDATE - faengt den Fall ab dass die Profile-Row
      // noch nicht existiert (z.B. bei Test-Accounts oder wenn der
      // Bootstrap-Trigger aus irgendeinem Grund nicht gegriffen hat).
      // .select().single() erzwingt eine Antwort - bei RLS-Block oder
      // 0-rows kommt eine PostgrestException statt stiller No-Op.
      await _client.from('profiles').upsert(payload).select().single();
    } catch (e, stack) {
      dev.log('ProfileSync.save failed', error: e, stackTrace: stack, name: 'profile_sync');
      rethrow;
    }
  }

  static BiologicalSex _parseSex(String? raw) {
    if (raw == null) return BiologicalSex.neutral;
    return BiologicalSex.values.firstWhere(
      (v) => v.name == raw,
      orElse: () => BiologicalSex.neutral,
    );
  }

  static int? _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

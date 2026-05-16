import 'dart:developer' as dev;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/caffeine_entry.dart';
import '../models/sleep_entry.dart';
import '../models/weight_log.dart';

/// Buendelt Sync fuer kleine Zeitreihen: weight_log, caffeine_entries,
/// sleep_entries. Jede Methode ist atomar gegen ihre Tabelle.
class TrackingSync {
  TrackingSync(this._client, this._userId);

  final SupabaseClient _client;
  final String _userId;

  // ---------- weight_log ----------

  Future<WeightLog> loadWeightLog() async {
    try {
      final rows = await _client
          .from('weight_log')
          .select('recorded_at, weight_kg')
          .eq('user_id', _userId)
          .order('recorded_at', ascending: true);
      final entries = rows.map<WeightLogEntry>((row) {
        return WeightLogEntry(
          timestamp:
              DateTime.parse(row['recorded_at'] as String).toLocal(),
          weightKg: (row['weight_kg'] as num).toDouble(),
        );
      }).toList();
      return WeightLog(entries: entries);
    } catch (e, stack) {
      dev.log('TrackingSync.loadWeightLog failed',
          error: e, stackTrace: stack, name: 'tracking_sync');
      rethrow;
    }
  }

  Future<void> insertWeight(double weightKg, DateTime timestamp) async {
    try {
      await _client.from('weight_log').insert({
        'user_id': _userId,
        'recorded_at': timestamp.toUtc().toIso8601String(),
        'weight_kg': weightKg,
      });
    } catch (e, stack) {
      dev.log('TrackingSync.insertWeight failed',
          error: e, stackTrace: stack, name: 'tracking_sync');
      rethrow;
    }
  }

  // ---------- caffeine_entries ----------

  Future<CaffeineDay> loadCaffeineDay(DateTime date) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    try {
      final rows = await _client
          .from('caffeine_entries')
          .select('consumed_at, mg')
          .eq('user_id', _userId)
          .gte('consumed_at', dayStart.toUtc().toIso8601String())
          .lt('consumed_at', dayEnd.toUtc().toIso8601String())
          .order('consumed_at', ascending: true);
      final entries = rows.map<CaffeineEntry>((row) {
        return CaffeineEntry(
          timestamp:
              DateTime.parse(row['consumed_at'] as String).toLocal(),
          mg: (row['mg'] as num).toInt(),
        );
      }).toList();
      return CaffeineDay(entries: entries);
    } catch (e, stack) {
      dev.log('TrackingSync.loadCaffeineDay failed',
          error: e, stackTrace: stack, name: 'tracking_sync');
      rethrow;
    }
  }

  Future<void> insertCaffeine(int mg, DateTime timestamp) async {
    try {
      await _client.from('caffeine_entries').insert({
        'user_id': _userId,
        'consumed_at': timestamp.toUtc().toIso8601String(),
        'mg': mg,
      });
    } catch (e, stack) {
      dev.log('TrackingSync.insertCaffeine failed',
          error: e, stackTrace: stack, name: 'tracking_sync');
      rethrow;
    }
  }

  Future<void> resetCaffeineDay(DateTime date) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    try {
      await _client
          .from('caffeine_entries')
          .delete()
          .eq('user_id', _userId)
          .gte('consumed_at', dayStart.toUtc().toIso8601String())
          .lt('consumed_at', dayEnd.toUtc().toIso8601String());
    } catch (e, stack) {
      dev.log('TrackingSync.resetCaffeineDay failed',
          error: e, stackTrace: stack, name: 'tracking_sync');
      rethrow;
    }
  }

  // ---------- sleep_entries ----------

  Future<SleepEntry?> loadLatestSleep() async {
    try {
      final rows = await _client
          .from('sleep_entries')
          .select('sleep_date, bedtime_minutes, wake_minutes, quality')
          .eq('user_id', _userId)
          .order('sleep_date', ascending: false)
          .limit(1);
      if (rows.isEmpty) return null;
      final row = rows.first;
      return SleepEntry(
        date: DateTime.parse(row['sleep_date'] as String),
        bedtimeMinutes: (row['bedtime_minutes'] as num).toInt(),
        wakeMinutes: (row['wake_minutes'] as num).toInt(),
        quality: (row['quality'] as num).toInt(),
      );
    } catch (e, stack) {
      dev.log('TrackingSync.loadLatestSleep failed',
          error: e, stackTrace: stack, name: 'tracking_sync');
      rethrow;
    }
  }

  Future<void> upsertSleep(SleepEntry entry) async {
    try {
      await _client.from('sleep_entries').upsert({
        'user_id': _userId,
        'sleep_date': _dateOnly(entry.date),
        'bedtime_minutes': entry.bedtimeMinutes,
        'wake_minutes': entry.wakeMinutes,
        'quality': entry.quality,
      }, onConflict: 'user_id,sleep_date');
    } catch (e, stack) {
      dev.log('TrackingSync.upsertSleep failed',
          error: e, stackTrace: stack, name: 'tracking_sync');
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

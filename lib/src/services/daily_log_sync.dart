import 'dart:async';
import 'dart:developer' as dev;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/daily_mood.dart';
import '../models/habit.dart';

/// Snapshot des taeglichen Tagesstands. Ein DailyLog = eine Zeile
/// in public.daily_logs (primary key user_id+log_date).
class DailyLog {
  const DailyLog({
    required this.date,
    this.waterMl = 0,
    this.steps = 0,
    this.moodScore = 0,
    this.moodNote = '',
    this.completedBlockIds = const <String>{},
    this.completedHabitIds = const <String>{},
  });

  final DateTime date;
  final int waterMl;
  final int steps;
  final int moodScore;
  final String moodNote;
  final Set<String> completedBlockIds;
  final Set<String> completedHabitIds;

  DailyMood get mood => DailyMood(score: moodScore, note: moodNote);
  HabitState get habitState => HabitState(completedIds: completedHabitIds);
}

class DailyLogSync {
  DailyLogSync(this._client, this._userId);

  final SupabaseClient _client;
  final String _userId;

  // Debounce - mehrere setState in Folge sammeln und in einem Upsert raus.
  Timer? _debounce;
  DailyLog? _pending;

  void dispose() {
    _debounce?.cancel();
  }

  Future<DailyLog?> loadForDate(DateTime date) async {
    final iso = _dateOnly(date);
    try {
      final row = await _client
          .from('daily_logs')
          .select(
              'log_date, water_ml, steps, mood_score, mood_note, completed_block_ids, completed_habit_ids')
          .eq('user_id', _userId)
          .eq('log_date', iso)
          .maybeSingle();
      if (row == null) return null;
      return DailyLog(
        date: DateTime.parse(row['log_date'] as String),
        waterMl: (row['water_ml'] as num?)?.toInt() ?? 0,
        steps: (row['steps'] as num?)?.toInt() ?? 0,
        moodScore: (row['mood_score'] as num?)?.toInt() ?? 0,
        moodNote: row['mood_note']?.toString() ?? '',
        completedBlockIds:
            _stringSet(row['completed_block_ids']),
        completedHabitIds:
            _stringSet(row['completed_habit_ids']),
      );
    } catch (e, stack) {
      dev.log('DailyLogSync.loadForDate failed',
          error: e, stackTrace: stack, name: 'daily_log_sync');
      rethrow;
    }
  }

  /// Debounced Upsert. setState-Hagel aus dem HomeState laufen in 400ms-
  /// Fenstern zusammen und werden als ein UPSERT geschrieben.
  void queueUpsert(DailyLog log) {
    _pending = log;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final next = _pending;
      _pending = null;
      if (next != null) {
        unawaited(_upsert(next));
      }
    });
  }

  /// Sofortiger Flush (z.B. beim App-Pausieren).
  Future<void> flush() async {
    _debounce?.cancel();
    _debounce = null;
    final next = _pending;
    _pending = null;
    if (next != null) {
      await _upsert(next);
    }
  }

  Future<void> _upsert(DailyLog log) async {
    try {
      await _client.from('daily_logs').upsert({
        'user_id': _userId,
        'log_date': _dateOnly(log.date),
        'water_ml': log.waterMl,
        'steps': log.steps,
        'mood_score': log.moodScore,
        'mood_note': log.moodNote,
        'completed_block_ids': log.completedBlockIds.toList(),
        'completed_habit_ids': log.completedHabitIds.toList(),
      }, onConflict: 'user_id,log_date');
    } catch (e, stack) {
      dev.log('DailyLogSync._upsert failed',
          error: e, stackTrace: stack, name: 'daily_log_sync');
      // Nicht rethrow - das ist fire-and-forget aus dem Timer raus.
    }
  }

  static String _dateOnly(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static Set<String> _stringSet(Object? raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).toSet();
    }
    return <String>{};
  }
}

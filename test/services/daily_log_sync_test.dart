import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase/supabase.dart';

import 'package:shiftfit/src/services/daily_log_sync.dart';

// INT-1 / DATA-2: Der daily_logs-Schreibpfad ist jetzt so sicher wie der
// Mahlzeiten-Pfad. DailyLogSync._upsert reicht einen Fehler an den
// onError-Callback weiter (statt ihn nur per dev.log zu schlucken), damit der
// Aufrufer den Tagesstand vom Server re-syncen kann. Diese Tests treiben den
// echten SupabaseClient mit einem MockClient und verifizieren:
//   1. Ein 500-Upsert ruft onError mit dem geworfenen Fehler.
//   2. Ein erfolgreicher Upsert ruft onError NICHT.
//   3. Eine in onError geworfene Exception killt den Upsert-Pfad nicht.

DailyLogSync _sync(
  Future<http.Response> Function(http.Request request) handler, {
  void Function(Object error)? onError,
}) {
  final client = SupabaseClient(
    'https://example.supabase.co',
    'test-anon-key',
    httpClient: MockClient((req) => handler(req)),
  );
  addTearDown(client.dispose);
  return DailyLogSync(client, 'user-123', onError: onError);
}

DailyLog _log() => DailyLog(
      date: DateTime(2026, 6, 4),
      waterMl: 1500,
      steps: 8000,
      moodScore: 4,
      moodNote: 'gut',
      completedBlockIds: const <String>{'1:Warm-up'},
      completedHabitIds: const <String>{'wasser'},
      workoutCompleted: true,
    );

void main() {
  group('DailyLogSync._upsert Fehlerpfad', () {
    test('Upsert-Fehler (500) ruft onError mit dem geworfenen Fehler', () async {
      Object? reported;
      final sync = _sync(
        (req) async => http.Response(
          jsonEncode({'message': 'permission denied'}),
          500,
          headers: const {'Content-Type': 'application/json'},
        ),
        onError: (e) => reported = e,
      );

      // queueUpsert dispatcht via Timer/unawaited; flush() erzwingt den Write
      // sofort und awaitet ihn deterministisch.
      sync.queueUpsert(_log());
      await sync.flush();

      expect(reported, isNotNull,
          reason: 'onError muss bei einem fehlgeschlagenen Upsert feuern');
    });

    test('erfolgreicher Upsert ruft onError NICHT', () async {
      var called = false;
      final sync = _sync(
        (req) async => http.Response('', 201, request: req),
        onError: (_) => called = true,
      );

      sync.queueUpsert(_log());
      await sync.flush();

      expect(called, isFalse);
    });

    test('eine in onError geworfene Exception killt den Upsert-Pfad nicht', () async {
      final sync = _sync(
        (req) async => http.Response(
          jsonEncode({'message': 'boom'}),
          500,
          headers: const {'Content-Type': 'application/json'},
        ),
        onError: (_) => throw StateError('callback exploded'),
      );

      sync.queueUpsert(_log());
      // Darf NICHT durchschlagen — der Callback-Fehler wird intern geschluckt.
      await expectLater(sync.flush(), completes);
    });
  });
}

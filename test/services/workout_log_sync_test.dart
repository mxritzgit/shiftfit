import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase/supabase.dart';

import 'package:shiftfit/src/models/workout_set.dart';
import 'package:shiftfit/src/services/workout_log_sync.dart';

// PROD-5: WorkoutLogSync gegen einen echten SupabaseClient + Mock-HTTP.
// Verifiziert ueber die PUBLIC API das beobachtbare Persistenz-Verhalten:
// idempotenter Upsert (onConflict id), user_id-Filter, local_day-Query,
// Delete-Filter.

WorkoutLogSync _sync(
  Future<http.Response> Function(http.Request request) handler,
) {
  final client = SupabaseClient(
    'https://example.supabase.co',
    'test-anon-key',
    httpClient: MockClient((req) => handler(req)),
  );
  addTearDown(client.dispose);
  return WorkoutLogSync(client, 'user-123');
}

WorkoutSet _set() {
  return WorkoutSet(
    id: 'set-uuid-1',
    exerciseId: 'bench_press',
    weightKg: 82.5,
    reps: 5,
    rpe: 8,
    loggedAt: DateTime.utc(2026, 6, 4, 16, 0),
    localDay: '2026-06-04',
  );
}

void main() {
  group('WorkoutLogSync', () {
    test('insert nutzt idempotenten Upsert (onConflict id) + sendet user_id',
        () async {
      String? prefer;
      Map<String, dynamic>? body;
      final sync = _sync((req) async {
        prefer = req.headers['Prefer'];
        final decoded = jsonDecode(req.body);
        body = (decoded is List ? decoded.first : decoded)
            as Map<String, dynamic>;
        return http.Response('', 201, request: req);
      });

      await sync.insert(_set());

      expect(prefer, contains('resolution=merge-duplicates'));
      expect(body, containsPair('user_id', 'user-123'));
      expect(body, containsPair('id', 'set-uuid-1'));
      expect(body, containsPair('exercise', 'bench_press'));
      expect(body, containsPair('weight_kg', 82.5));
      expect(body, containsPair('reps', 5));
      expect(body, containsPair('rpe', 8));
      expect(body, containsPair('local_day', '2026-06-04'));
    });

    test('loadRecent filtert auf user_id, sortiert, limitiert', () async {
      String? url;
      final sync = _sync((req) async {
        url = req.url.toString();
        final rows = [
          {
            'id': 'a',
            'exercise': 'squat',
            'weight_kg': 100,
            'reps': 5,
            'rpe': null,
            'logged_at': DateTime.utc(2026, 6, 4, 10).toIso8601String(),
            'local_day': '2026-06-04',
          },
        ];
        return http.Response(
          jsonEncode(rows),
          200,
          headers: const {'Content-Type': 'application/json'},
          request: req,
        );
      });

      final sets = await sync.loadRecent(limit: 50);
      expect(sets.length, 1);
      expect(sets.first.exerciseId, 'squat');
      expect(sets.first.weightKg, 100);
      expect(url, contains('user_id=eq.user-123'));
      expect(url, contains('limit=50'));
      expect(url, contains('order='));
    });

    test('loadByLocalDay filtert auf user_id + local_day', () async {
      String? url;
      final sync = _sync((req) async {
        url = req.url.toString();
        return http.Response(
          jsonEncode(const []),
          200,
          headers: const {'Content-Type': 'application/json'},
          request: req,
        );
      });

      await sync.loadByLocalDay('2026-06-04');
      expect(url, contains('user_id=eq.user-123'));
      expect(url, contains('local_day=eq.2026-06-04'));
    });

    test('delete filtert auf id + user_id', () async {
      String? method;
      String? url;
      final sync = _sync((req) async {
        method = req.method;
        url = req.url.toString();
        return http.Response('', 204, request: req);
      });

      await sync.delete('set-uuid-1');

      expect(method, 'DELETE');
      expect(url, contains('id=eq.set-uuid-1'));
      expect(url, contains('user_id=eq.user-123'));
    });
  });
}

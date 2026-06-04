import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase/supabase.dart';

import 'package:shiftfit/src/services/local_day.dart';
import 'package:shiftfit/src/services/tracking_sync.dart';

// DATA-6: Kanonischer lokaler Tages-Schluessel.
//
// 1) localDayKey ist eine reine, stabile YYYY-MM-DD-Funktion (byte-genau zu
//    daily_log_sync/tracking_sync._dateOnly).
// 2) Der Caffeine-Sync filtert beim Lesen/Loeschen auf local_day=eq und
//    schreibt local_day aus der LOKALEN Wanduhr des Eintrags — nicht mehr ueber
//    ein UTC-Halboffenes Fenster.

TrackingSync _sync(
  Future<http.Response> Function(http.Request request) handler,
) {
  final client = SupabaseClient(
    'https://example.supabase.co',
    'test-anon-key',
    httpClient: MockClient((req) => handler(req)),
  );
  addTearDown(client.dispose);
  return TrackingSync(client, 'user-123');
}

void main() {
  group('localDayKey (rein + stabil)', () {
    test('formatiert YYYY-MM-DD mit Zero-Padding', () {
      expect(localDayKey(DateTime(2026, 6, 4, 23, 45)), '2026-06-04');
      expect(localDayKey(DateTime(2026, 1, 9, 0, 1)), '2026-01-09');
      expect(localDayKey(DateTime(7, 2, 3)), '0007-02-03');
    });

    test('haengt nur am Kalendertag, nicht an der Uhrzeit', () {
      final day = DateTime(2026, 6, 4);
      expect(localDayKey(DateTime(2026, 6, 4, 0, 0)), localDayKey(day));
      expect(localDayKey(DateTime(2026, 6, 4, 23, 59, 59)), localDayKey(day));
    });

    test('deterministisch ueber mehrfachen Aufruf', () {
      final t = DateTime(2026, 6, 4, 23, 45);
      expect(localDayKey(t), localDayKey(t));
    });
  });

  group('TrackingSync caffeine filtert/schreibt auf local_day', () {
    test('loadCaffeineDay filtert local_day=eq (kein UTC-Fenster)', () async {
      Uri? url;
      final sync = _sync((req) async {
        url = req.url;
        return http.Response('[]', 200,
            request: req,
            headers: const {'Content-Type': 'application/json'});
      });

      await sync.loadCaffeineDay(DateTime(2026, 6, 4, 23, 45));

      final query = url!.query;
      // Genau ein eq-Filter auf den lokalen Tagesschluessel ...
      expect(query, contains('local_day=eq.2026-06-04'));
      // ... und KEIN gte/lt-Fenster mehr auf consumed_at.
      expect(query, isNot(contains('consumed_at=gte')));
      expect(query, isNot(contains('consumed_at=lt')));
    });

    test('insertCaffeine schreibt local_day aus der lokalen Wanduhr', () async {
      Map<String, dynamic>? body;
      final sync = _sync((req) async {
        final decoded = jsonDecode(req.body);
        body = (decoded is List ? decoded.first : decoded)
            as Map<String, dynamic>;
        return http.Response('', 201, request: req);
      });

      // 23:45 lokal am 4. Juni -> local_day MUSS 2026-06-04 sein, egal wohin
      // der UTC-Timestamp faellt.
      await sync.insertCaffeine(95, DateTime(2026, 6, 4, 23, 45));

      expect(body, containsPair('local_day', '2026-06-04'));
      expect(body, containsPair('mg', 95));
    });

    test('resetCaffeineDay loescht ueber local_day=eq', () async {
      Uri? url;
      final sync = _sync((req) async {
        url = req.url;
        return http.Response('', 204, request: req);
      });

      await sync.resetCaffeineDay(DateTime(2026, 6, 4, 8, 0));

      expect(url!.query, contains('local_day=eq.2026-06-04'));
    });
  });
}

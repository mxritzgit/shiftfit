import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shiftfit/src/app/shiftfit_home_page.dart';
import 'package:shiftfit/src/models/caffeine_entry.dart';
import 'package:shiftfit/src/models/lifetime_stats.dart';
import 'package:shiftfit/src/services/notification_content_engine.dart';
import 'package:shiftfit/src/services/notification_service.dart';
import 'package:shiftfit/src/theme/app_theme.dart';

// PROD-1 Wiring-Tests: beweisen, dass ShiftFitHomePage die NotificationService-
// Schicht korrekt ansteuert — scheduleAll wenn der User-Toggle AN ist (Opt-in +
// Datenaenderung), cancelAll wenn er AUS-geschaltet wird. Es wird ein
// aufzeichnender Mock injiziert; KEIN echter Plattform-Channel wird beruehrt
// (sync == null -> die Page landet direkt auf dem Home, kein Onboarding/Boot).

/// Aufzeichnender Mock: zaehlt die Aufrufe und merkt sich die letzten Specs.
class _RecordingNotificationService implements NotificationService {
  int initCalls = 0;
  int permissionCalls = 0;
  int scheduleCalls = 0;
  int cancelCalls = 0;
  List<NotificationSpec> lastSpecs = const <NotificationSpec>[];

  @override
  Future<void> init() async => initCalls++;

  @override
  Future<bool> requestPermission() async {
    permissionCalls++;
    return true;
  }

  @override
  Future<void> scheduleAll(List<NotificationSpec> specs) async {
    scheduleCalls++;
    lastSpecs = specs;
  }

  @override
  Future<void> cancelAll() async => cancelCalls++;
}

void main() {
  // Default-Konstruktor ist der Noop-Service: keine Plattform-Calls, kein Crash.
  test('home page defaults to NoopNotificationService (test-safe)', () {
    final page = ShiftFitHomePage(initialUserName: 'Moritz');
    expect(page.notificationService, isA<NoopNotificationService>());
  });

  testWidgets(
      'settings toggle ON requests permission + schedules, OFF cancels',
      (tester) async {
    // Viewport auf iPhone-Portrait pinnen + RenderFlex-Overflow schlucken
    // (mirror des CI-Harness in widget_test.dart) — sonst werfen feste
    // Container im 800x600-Default-Viewport.
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final prior = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception.toString().contains('overflowed')) return;
      prior?.call(details);
    };
    addTearDown(() => FlutterError.onError = prior);

    final service = _RecordingNotificationService();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildShiftFitTheme(),
        // sync == null -> direkt auf dem Home, kein Onboarding-Gate. Der
        // injizierte Mock ist der einzige Notification-Pfad.
        home: ShiftFitHomePage(
          initialUserName: 'Moritz',
          notificationService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Startzustand: nichts geplant, nichts angefragt (Default OFF).
    expect(service.scheduleCalls, 0);
    expect(service.permissionCalls, 0);

    // Settings oeffnen.
    await tester.tap(find.byKey(const ValueKey('topbar-settings')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('settings-notifications')), findsOneWidget);

    // Erinnerungen einschalten + speichern (Sheet ist scrollbar -> sichtbar
    // machen, sonst liegt der Schalter/der Save-Button unter dem Fold).
    await tester.ensureVisible(find.byKey(const ValueKey('settings-notifications')));
    await tester.tap(find.byKey(const ValueKey('settings-notifications')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('settings-save')));
    await tester.tap(find.byKey(const ValueKey('settings-save')));
    await tester.pumpAndSettle();

    // _setNotificationsEnabled(true): init + Permission + sofortiges scheduleAll.
    expect(service.permissionCalls, 1);
    expect(service.scheduleCalls, greaterThanOrEqualTo(1));
    final schedulesAfterOptIn = service.scheduleCalls;

    // Datenaenderung bei aktivem Toggle: erneutes Oeffnen + Speichern der
    // Settings ruft am Ende von _openSettings den debounced Reschedule auf.
    await tester.tap(find.byKey(const ValueKey('topbar-settings')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('settings-save')));
    await tester.tap(find.byKey(const ValueKey('settings-save')));
    // Sheet-Dismiss settlen lassen -> _openSettings laeuft weiter und plant den
    // debounced Reschedule-Timer (700ms).
    await tester.pumpAndSettle();
    // Debounce-Fenster ablaufen lassen -> ein weiteres scheduleAll feuert.
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(service.scheduleCalls, greaterThan(schedulesAfterOptIn));
    // Toggle blieb AN -> kein cancelAll bisher.
    expect(service.cancelCalls, 0);

    // Erneut oeffnen und AUS-schalten -> cancelAll, keine neue Permission.
    final permissionsBeforeOff = service.permissionCalls;
    await tester.tap(find.byKey(const ValueKey('topbar-settings')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
        find.byKey(const ValueKey('settings-notifications')));
    await tester.tap(find.byKey(const ValueKey('settings-notifications')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('settings-save')));
    await tester.tap(find.byKey(const ValueKey('settings-save')));
    await tester.pumpAndSettle();

    expect(service.cancelCalls, 1);
    // Beim Ausschalten wird KEINE Permission erneut angefragt.
    expect(service.permissionCalls, permissionsBeforeOff);

    // Etwaige noch ausstehende Debounce-Timer austrocknen, damit der Test-
    // Teardown nicht ueber einen pending Timer stolpert.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }, skip: false);

  test('engine builds a hydration spec from low water (sanity for wiring)', () {
    // Spiegelt die Eingaben, die _pushSchedule aus dem Live-State zieht, und
    // bestaetigt, dass die Engine daraus ueberhaupt einen Spec macht — damit
    // ein scheduleAll im AN-Zustand auch Inhalt transportiert.
    final specs = const NotificationContentEngine().buildSchedule(
      now: DateTime(2026, 6, 4, 9),
      shift: 'Muskelaufbau',
      dailyWaterMl: 0,
      waterGoalMl: 2500,
      caffeineDay: const CaffeineDay(),
      lastBedtimeMinutes: null,
      sleepGoalMinutes: 7 * 60 + 30,
      stats: LifetimeStats(sessionStart: DateTime(2026, 1, 1)),
    );
    expect(
      specs.any((s) => s.category == NotificationCategory.hydration),
      isTrue,
    );
  });
}

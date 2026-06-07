import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftfit/src/app/home_store.dart';
import 'package:shiftfit/src/services/health_service.dart';
import 'package:shiftfit/src/services/notification_service.dart';

/// Guard fuer das PERF-2-Scoping des Today-Dashboards: die in today_dashboard.dart
/// gewaehlten Sektions-Slices muessen wirklich unabhaengig sein. Aendert ein
/// Quick-Log eine fremde Sektion mit, rebuildet sie unnoetig — genau das, was der
/// Refactor abstellt. Diese Tests pinnen die Slice-Records gegen Regressionen.
void _noopSnack(
  String message, {
  IconData icon = Icons.info_outline,
  Color accent = const Color(0xFF000000),
  Duration? duration,
  SnackBarAction? action,
}) {}

HomeStore _store() => HomeStore(
      sync: null,
      health: const NoopHealthService(),
      notificationService: const NoopNotificationService(),
      initialUserName: 'Test',
      emitSnack: _noopSnack,
    );

void main() {
  // HapticFeedback (in addWater/setMoodScore) braucht ein initialisiertes
  // Test-Binding, sonst wirft der Platform-Channel.
  TestWidgetsFlutterBinding.ensureInitialized();

  // Die Slice-Records spiegeln EXAKT die Selektoren in today_dashboard.dart.
  Object wellbeing(HomeStore s) =>
      (s.mood, s.habits, s.caffeineDay, s.weightLog, s.selectedShift);
  Object tracker(HomeStore s) => (
        s.dailyWaterMl,
        s.profile.dailyWaterGoalMl,
        s.dailySteps,
        s.stepsGoal,
        s.lastSleep,
        s.profile.dailySleepGoalMinutes,
        s.dailyConsumedKcal,
        s.profile.dailyKcalGoal,
        s.completedBlockIds,
        s.plan.blocks.length,
        s.healthAuthState,
        s.healthLastFetch,
      );
  Object session(HomeStore s) => (
        s.selectedShift,
        s.selectedEnergy,
        s.selectedStress,
        s.completedBlockIds,
        s.workoutStreak,
      );

  test('addWater rebuildet Tracker, aber NICHT Wohlbefinden/Session', () {
    final s = _store();
    final wb = wellbeing(s);
    final se = session(s);
    final tr = tracker(s);

    s.addWater(250);

    expect(wellbeing(s), wb,
        reason: 'Wasser darf die Wohlbefinden-Slice nicht aendern');
    expect(session(s), se,
        reason: 'Wasser darf die Session-Slice nicht aendern');
    expect(tracker(s) == tr, isFalse,
        reason: 'Wasser MUSS die Tracker-Slice aendern');
  });

  test('setMoodScore rebuildet Wohlbefinden, aber NICHT Tracker/Session', () {
    final s = _store();
    final wb = wellbeing(s);
    final se = session(s);
    final tr = tracker(s);

    s.setMoodScore(s.mood.score == 4 ? 3 : 4);

    expect(wellbeing(s) == wb, isFalse,
        reason: 'Mood MUSS die Wohlbefinden-Slice aendern');
    expect(tracker(s), tr, reason: 'Mood darf die Tracker-Slice nicht aendern');
    expect(session(s), se,
        reason: 'Mood darf die Session-Slice nicht aendern');
  });

  test('toggleHabit rebuildet nur Wohlbefinden', () {
    final s = _store();
    final tr = tracker(s);
    final se = session(s);
    final wb = wellbeing(s);

    s.toggleHabit('hydration');

    expect(wellbeing(s) == wb, isFalse,
        reason: 'Habit MUSS die Wohlbefinden-Slice aendern');
    expect(tracker(s), tr);
    expect(session(s), se);
  });
}

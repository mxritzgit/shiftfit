import 'dart:io';

import 'package:health/health.dart';

import 'health_service.dart';

class AppleHealthService implements HealthService {
  AppleHealthService();

  final Health _health = Health();
  HealthAuthState _authState = HealthAuthState.unknown;
  bool _configured = false;

  static const _types = [HealthDataType.STEPS];
  static const _permissions = [HealthDataAccess.READ];

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  @override
  HealthAuthState get authState => _authState;

  @override
  Future<HealthAuthState> requestAuthorization() async {
    // Defense-in-depth: HealthKit gibt es nur auf iOS. Die Auswahl Apple-vs-
    // Noop passiert zwar schon beim Aufbau, aber falls diese Instanz doch auf
    // einer anderen Plattform landet, no-op-pen wir hart statt zu crashen.
    if (!Platform.isIOS) {
      _authState = HealthAuthState.unsupported;
      return _authState;
    }
    try {
      await _ensureConfigured();
      final hasPermissions =
          await _health.hasPermissions(_types, permissions: _permissions) ?? false;
      if (hasPermissions) {
        _authState = HealthAuthState.granted;
        return _authState;
      }
      final granted = await _health.requestAuthorization(
        _types,
        permissions: _permissions,
      );
      _authState =
          granted ? HealthAuthState.granted : HealthAuthState.denied;
      return _authState;
    } catch (_) {
      _authState = HealthAuthState.unsupported;
      return _authState;
    }
  }

  @override
  Future<HealthSnapshot?> readSnapshot() async {
    if (!Platform.isIOS) return null;
    try {
      await _ensureConfigured();
      if (_authState != HealthAuthState.granted) {
        final hasPermissions = await _health
                .hasPermissions(_types, permissions: _permissions) ??
            false;
        if (!hasPermissions) {
          return null;
        }
        _authState = HealthAuthState.granted;
      }

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final steps = await _health.getTotalStepsInInterval(startOfDay, now);
      if (steps == null) return null;
      return HealthSnapshot(stepsToday: steps, fetchedAt: now);
    } catch (_) {
      return null;
    }
  }
}

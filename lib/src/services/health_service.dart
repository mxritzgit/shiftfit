enum HealthAuthState { unknown, granted, denied, unsupported }

class HealthSnapshot {
  const HealthSnapshot({required this.stepsToday, required this.fetchedAt});

  final int stepsToday;
  final DateTime fetchedAt;
}

abstract class HealthService {
  HealthAuthState get authState;

  /// Triggers the system permission prompt. Returns the resulting auth state.
  Future<HealthAuthState> requestAuthorization();

  /// Reads today's step count. Returns null when not authorized or no data.
  Future<HealthSnapshot?> readSnapshot();
}

class NoopHealthService implements HealthService {
  const NoopHealthService();

  @override
  HealthAuthState get authState => HealthAuthState.unsupported;

  @override
  Future<HealthAuthState> requestAuthorization() async =>
      HealthAuthState.unsupported;

  @override
  Future<HealthSnapshot?> readSnapshot() async => null;
}

class SleepEntry {
  const SleepEntry({
    required this.date,
    required this.bedtimeMinutes,
    required this.wakeMinutes,
    required this.quality,
  });

  /// Day on which the user woke up. Stored as date with time stripped.
  final DateTime date;

  /// Bedtime minutes-of-day (0..1439). May represent the previous day in real
  /// life if > wakeMinutes, in which case duration wraps past midnight.
  final int bedtimeMinutes;

  /// Wake time minutes-of-day (0..1439).
  final int wakeMinutes;

  /// Subjective quality 1..5.
  final int quality;

  Duration get duration {
    final raw = wakeMinutes - bedtimeMinutes;
    final mins = raw >= 0 ? raw : raw + 24 * 60;
    return Duration(minutes: mins);
  }

  String get durationLabel {
    final d = duration;
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }

  String get bedtimeLabel => _formatHm(bedtimeMinutes);
  String get wakeLabel => _formatHm(wakeMinutes);

  static String _formatHm(int minutesOfDay) {
    final h = (minutesOfDay ~/ 60) % 24;
    final m = minutesOfDay % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}

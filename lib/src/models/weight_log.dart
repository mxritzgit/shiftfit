class WeightLogEntry {
  const WeightLogEntry({required this.timestamp, required this.weightKg});

  final DateTime timestamp;
  final double weightKg;
}

class WeightLog {
  const WeightLog({this.entries = const <WeightLogEntry>[]});

  final List<WeightLogEntry> entries;

  WeightLogEntry? get latest => entries.isEmpty ? null : entries.last;

  double? get trendDelta {
    if (entries.length < 2) return null;
    return entries.last.weightKg - entries.first.weightKg;
  }

  WeightLog add(double kg) {
    if (kg <= 0) return this;
    final entry = WeightLogEntry(timestamp: DateTime.now(), weightKg: kg);
    final trimmed = [...entries, entry];
    if (trimmed.length > 30) {
      trimmed.removeRange(0, trimmed.length - 30);
    }
    return WeightLog(entries: trimmed);
  }

  WeightLog clear() => const WeightLog();
}

class CaffeineEntry {
  const CaffeineEntry({required this.timestamp, required this.mg});

  final DateTime timestamp;
  final int mg;

  String get clockLabel {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class CaffeineDay {
  const CaffeineDay({this.entries = const <CaffeineEntry>[]});

  final List<CaffeineEntry> entries;

  int get totalMg => entries.fold(0, (sum, entry) => sum + entry.mg);
  int get cups => entries.length;
  DateTime? get lastTime =>
      entries.isEmpty ? null : entries.last.timestamp;

  CaffeineDay add(int mg) {
    return CaffeineDay(
      entries: [...entries, CaffeineEntry(timestamp: DateTime.now(), mg: mg)],
    );
  }

  CaffeineDay reset() => const CaffeineDay();

  CaffeineDay removeAt(int index) {
    if (index < 0 || index >= entries.length) return this;
    final next = [...entries]..removeAt(index);
    return CaffeineDay(entries: next);
  }
}

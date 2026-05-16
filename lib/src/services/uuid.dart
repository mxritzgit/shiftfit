import 'dart:math';

/// Erzeugt eine UUID v4 ohne externe Dependency. Reicht voellig fuer
/// Client-seitige IDs die als Primary Key in Supabase wandern.
String uuidV4() {
  final rand = Random.secure();
  final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
  // Version 4 + RFC 4122 Variant.
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String hex(int b) => b.toRadixString(16).padLeft(2, '0');
  final h = bytes.map(hex).toList();
  return '${h.sublist(0, 4).join()}-'
      '${h.sublist(4, 6).join()}-'
      '${h.sublist(6, 8).join()}-'
      '${h.sublist(8, 10).join()}-'
      '${h.sublist(10, 16).join()}';
}

import 'dart:typed_data';

/// Eine einzelne Nachricht im Coach-Chat. role ist user|assistant - die
/// system-Rolle bleibt serverseitig und wird hier nicht modelliert.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.refusal = false,
    this.imageBytes,
    this.mediaLabel,
  });

  final String id;
  final ChatRole role;
  final String content;
  final DateTime createdAt;
  final bool refusal;

  /// Nur fuer frisch gesendete lokale Nachrichten. Historie aus Supabase
  /// speichert aktuell bewusst keine Bilddaten, damit die Tabelle schlank und
  /// privat bleibt.
  final Uint8List? imageBytes;
  final String? mediaLabel;

  factory ChatMessage.fromRow(Map<String, dynamic> row) {
    final roleRaw = row['role']?.toString() ?? 'assistant';
    return ChatMessage(
      id: row['id']?.toString() ?? '',
      role: roleRaw == 'user' ? ChatRole.user : ChatRole.assistant,
      content: row['content']?.toString() ?? '',
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      refusal: row['refusal'] == true,
    );
  }

  ChatMessage copyWith({String? content, bool? refusal}) {
    return ChatMessage(
      id: id,
      role: role,
      content: content ?? this.content,
      createdAt: createdAt,
      refusal: refusal ?? this.refusal,
      imageBytes: imageBytes,
      mediaLabel: mediaLabel,
    );
  }
}

enum ChatRole { user, assistant }

/// Snapshot der Quota fuer den Counter im UI.
class ChatQuotaSnapshot {
  const ChatQuotaSnapshot({
    required this.used,
    required this.remaining,
    required this.dailyLimit,
  });

  final int used;
  final int remaining;
  final int dailyLimit;

  static const ChatQuotaSnapshot unknown = ChatQuotaSnapshot(
    used: 0,
    remaining: 5,
    dailyLimit: 5,
  );

  ChatQuotaSnapshot copyWith({int? used, int? remaining, int? dailyLimit}) {
    return ChatQuotaSnapshot(
      used: used ?? this.used,
      remaining: remaining ?? this.remaining,
      dailyLimit: dailyLimit ?? this.dailyLimit,
    );
  }
}

/// Eine Chat-Session = ein Konversations-Thread im Coach-Tab.
class ChatSession {
  const ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.lastMessageAt,
    required this.messageCount,
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final int messageCount;

  bool get isEmpty => messageCount == 0;

  factory ChatSession.fromRow(Map<String, dynamic> row) {
    return ChatSession(
      id: row['id']?.toString() ?? '',
      title: (row['title']?.toString().trim().isNotEmpty ?? false)
          ? row['title'].toString().trim()
          : 'Neue Unterhaltung',
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      lastMessageAt:
          DateTime.parse(row['last_message_at'] as String).toLocal(),
      messageCount: (row['message_count'] as num?)?.toInt() ?? 0,
    );
  }

  ChatSession copyWith({
    String? title,
    DateTime? lastMessageAt,
    int? messageCount,
  }) {
    return ChatSession(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      messageCount: messageCount ?? this.messageCount,
    );
  }
}

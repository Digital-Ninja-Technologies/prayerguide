class JournalEntry {
  JournalEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String type; // Gratitude | Request | Testimony | Reflection
  final String title;
  final String body;
  final DateTime createdAt;

  factory JournalEntry.fromMap(Map<String, dynamic> m) => JournalEntry(
        id: m['id'] as String,
        type: m['type'] as String,
        title: m['title'] as String,
        body: (m['body'] as String?) ?? '',
        createdAt: DateTime.parse(m['created_at'] as String),
      );

  String get excerpt => body.length > 120 ? '${body.substring(0, 120)}…' : body;
}

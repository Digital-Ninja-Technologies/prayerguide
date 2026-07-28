class BibleNote {
  BibleNote({
    required this.id,
    required this.kind,
    required this.reference,
    this.verseText,
    this.note,
    required this.createdAt,
  });

  final String id;
  final String kind; // highlight | bookmark | note
  final String reference;
  final String? verseText;
  final String? note;
  final DateTime createdAt;

  factory BibleNote.fromMap(Map<String, dynamic> m) => BibleNote(
        id: m['id'] as String,
        kind: m['kind'] as String,
        reference: m['reference'] as String,
        verseText: m['verse_text'] as String?,
        note: m['note'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}

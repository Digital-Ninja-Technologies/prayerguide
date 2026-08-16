class SermonShare {
  SermonShare({
    required this.id,
    required this.sermonNoteId,
    required this.sermonTitle,
    required this.senderId,
    required this.senderName,
    required this.recipientId,
    required this.status,
    required this.createdAt,
    required this.respondedAt,
  });

  final String id;
  final String sermonNoteId;
  final String sermonTitle;
  final String senderId;
  final String senderName;
  final String recipientId;
  final String status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  /// The sender's name is a snapshot taken when the share was sent
  /// (`sermon_shares.sender_name`), not a live join — `profiles` RLS only
  /// allows viewing your own row or a paired companion's, and sharing works
  /// between any two users, not just companions.
  factory SermonShare.fromMap(Map<String, dynamic> m) {
    final noteRaw = m['sermon_notes'];
    final noteMap = noteRaw is List
        ? (noteRaw.isNotEmpty ? noteRaw.first as Map<String, dynamic> : null)
        : noteRaw as Map<String, dynamic>?;

    return SermonShare(
      id: m['id'] as String,
      sermonNoteId: m['sermon_note_id'] as String,
      sermonTitle: (noteMap?['title'] as String?) ?? 'Sermon note',
      senderId: m['sender_id'] as String,
      senderName: (m['sender_name'] as String?)?.trim().isNotEmpty == true
          ? m['sender_name'] as String
          : 'Someone',
      recipientId: m['recipient_id'] as String,
      status: m['status'] as String,
      createdAt: DateTime.parse(m['created_at'] as String),
      respondedAt: m['responded_at'] == null
          ? null
          : DateTime.parse(m['responded_at'] as String),
    );
  }
}

class UserSearchResult {
  UserSearchResult({required this.id, required this.name, required this.username});
  final String id;
  final String name;
  final String? username;

  factory UserSearchResult.fromMap(Map<String, dynamic> m) => UserSearchResult(
        id: m['id'] as String,
        name: (m['name'] as String?)?.trim().isNotEmpty == true
            ? m['name'] as String
            : 'Someone',
        username: m['username'] as String?,
      );
}

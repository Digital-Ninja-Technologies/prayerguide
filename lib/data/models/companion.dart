class Companion {
  Companion({
    required this.companionRowId,
    required this.otherUserId,
    required this.otherName,
    required this.otherStreak,
  });

  final String companionRowId;
  final String otherUserId;
  final String otherName;
  final int otherStreak;
}

class CompanionCheckinEntry {
  CompanionCheckinEntry(
      {required this.userId, required this.status, required this.createdAt});

  final String userId;
  final String status; // prayed | later | missed
  final DateTime createdAt;

  factory CompanionCheckinEntry.fromMap(Map<String, dynamic> m) =>
      CompanionCheckinEntry(
        userId: m['user_id'] as String,
        status: m['status'] as String,
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}

class SharedRequest {
  SharedRequest({
    required this.id,
    required this.userId,
    required this.category,
    required this.title,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String category;
  final String title;
  final DateTime createdAt;

  factory SharedRequest.fromMap(Map<String, dynamic> m) => SharedRequest(
        id: m['id'] as String,
        userId: m['user_id'] as String,
        category: m['category'] as String,
        title: m['title'] as String,
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}

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
  CompanionCheckinEntry({required this.userId, required this.status, required this.createdAt});

  final String userId;
  final String status; // prayed | later | missed
  final DateTime createdAt;

  factory CompanionCheckinEntry.fromMap(Map<String, dynamic> m) => CompanionCheckinEntry(
        userId: m['user_id'] as String,
        status: m['status'] as String,
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}

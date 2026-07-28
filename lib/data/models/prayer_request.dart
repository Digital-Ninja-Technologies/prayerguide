class PrayerRequest {
  PrayerRequest({
    required this.id,
    required this.category,
    required this.title,
    this.note,
    required this.status,
    required this.reminder,
    required this.sharedWithCompanion,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String category;
  final String title;
  final String? note;
  final String status; // active | answered | archived
  final bool reminder;
  final bool sharedWithCompanion;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory PrayerRequest.fromMap(Map<String, dynamic> m) => PrayerRequest(
        id: m['id'] as String,
        category: m['category'] as String,
        title: m['title'] as String,
        note: m['note'] as String?,
        status: m['status'] as String,
        reminder: (m['reminder'] as bool?) ?? false,
        sharedWithCompanion: (m['shared_with_companion'] as bool?) ?? false,
        createdAt: DateTime.parse(m['created_at'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String),
      );

  PrayerRequest copyWith({String? status, bool? reminder, bool? sharedWithCompanion}) => PrayerRequest(
        id: id,
        category: category,
        title: title,
        note: note,
        status: status ?? this.status,
        reminder: reminder ?? this.reminder,
        sharedWithCompanion: sharedWithCompanion ?? this.sharedWithCompanion,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}

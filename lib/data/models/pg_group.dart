class PgGroup {
  PgGroup({
    required this.id,
    required this.name,
    required this.meetingTime,
    required this.inviteCode,
    required this.createdBy,
    required this.memberCount,
  });

  final String id;
  final String name;
  final String? meetingTime;
  final String? inviteCode;
  final String createdBy;
  final int memberCount;

  factory PgGroup.fromMap(Map<String, dynamic> m, {int memberCount = 0}) => PgGroup(
        id: m['id'] as String,
        name: m['name'] as String,
        meetingTime: m['meeting_time'] as String?,
        inviteCode: m['invite_code'] as String?,
        createdBy: m['created_by'] as String,
        memberCount: memberCount,
      );
}

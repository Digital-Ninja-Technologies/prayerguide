class ReadingPlanProgress {
  ReadingPlanProgress({required this.planKey, required this.daysCompleted, required this.active});

  final String planKey;
  final int daysCompleted;
  final bool active;

  factory ReadingPlanProgress.fromMap(Map<String, dynamic> m) => ReadingPlanProgress(
        planKey: m['plan_key'] as String,
        daysCompleted: (m['days_completed'] as num?)?.toInt() ?? 0,
        active: (m['active'] as bool?) ?? false,
      );
}

class SubscriptionStatus {
  const SubscriptionStatus({required this.tier, required this.provider, required this.renewsAt});

  final String tier; // 'free' | 'premium'
  final String? provider; // e.g. 'trial', 'app_store', 'play_store'
  final DateTime? renewsAt;

  bool get isTrial => provider == 'trial';

  /// True while premium access should actually be granted — a trial whose
  /// renewsAt has passed no longer counts, even if `tier` is still
  /// 'premium' in the row (nothing flips that automatically without a
  /// server-side job, so this is computed live instead of trusted as-is).
  bool get isActive => tier == 'premium' && (renewsAt == null || renewsAt!.isAfter(DateTime.now()));

  static const free = SubscriptionStatus(tier: 'free', provider: null, renewsAt: null);

  factory SubscriptionStatus.fromMap(Map<String, dynamic> m) => SubscriptionStatus(
        tier: m['tier'] as String? ?? 'free',
        provider: m['provider'] as String?,
        renewsAt: m['renews_at'] == null ? null : DateTime.tryParse(m['renews_at'] as String),
      );
}

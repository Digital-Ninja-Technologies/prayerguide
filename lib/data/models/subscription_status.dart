import 'package:purchases_flutter/purchases_flutter.dart';

import '../../core/purchases/revenue_cat_service.dart';

class SubscriptionStatus {
  const SubscriptionStatus({
    required this.tier,
    required this.provider,
    required this.renewsAt,
    required this.willRenew,
    required this.isTrial,
  });

  final String tier; // 'free' | 'premium'
  final String? provider; // e.g. 'app_store', 'play_store'
  final DateTime? renewsAt;

  /// Whether the subscription is set to renew automatically. Only known
  /// live from RevenueCat — defaults to true when reconstructed from the
  /// Supabase cache row (see [fromMap]).
  final bool willRenew;

  /// Whether this is currently within a free-trial period offered by the
  /// store. Only known live from RevenueCat.
  final bool isTrial;

  bool get isActive => tier == 'premium';

  static const free = SubscriptionStatus(
    tier: 'free',
    provider: null,
    renewsAt: null,
    willRenew: false,
    isTrial: false,
  );

  /// From the cached `subscriptions` row in Supabase — a best-effort
  /// fallback for when RevenueCat isn't configured or unreachable.
  factory SubscriptionStatus.fromMap(Map<String, dynamic> m) =>
      SubscriptionStatus(
        tier: m['tier'] as String? ?? 'free',
        provider: m['provider'] as String?,
        renewsAt: m['renews_at'] == null
            ? null
            : DateTime.tryParse(m['renews_at'] as String),
        willRenew: true,
        isTrial: false,
      );

  /// From a live RevenueCat [CustomerInfo] — the source of truth whenever
  /// RevenueCat is configured.
  factory SubscriptionStatus.fromCustomerInfo(CustomerInfo info) {
    final ent = info.entitlements.active[kPremiumEntitlementId];
    if (ent == null) return SubscriptionStatus.free;
    return SubscriptionStatus(
      tier: 'premium',
      provider: _storeName(ent.store),
      renewsAt: DateTime.tryParse(ent.expirationDate ?? ''),
      willRenew: ent.willRenew,
      isTrial: ent.periodType == PeriodType.trial,
    );
  }

  static String _storeName(Store store) {
    switch (store) {
      case Store.appStore:
        return 'app_store';
      case Store.playStore:
        return 'play_store';
      default:
        return store.name;
    }
  }
}

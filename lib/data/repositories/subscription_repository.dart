import 'package:purchases_flutter/purchases_flutter.dart';

import '../../core/purchases/revenue_cat_service.dart';
import '../../core/supabase/supabase_config.dart';
import '../models/subscription_status.dart';

class SubscriptionRepository {
  final _rc = RevenueCatService.instance;

  bool get isConfigured => _rc.isConfigured;

  /// RevenueCat is the source of truth whenever it's configured. The
  /// `subscriptions` table is kept in sync server-side by the
  /// revenuecat-webhook Edge Function (not by this client — see
  /// migration 0016_security_audit_fixes.sql), so this only reads that
  /// cached row as a fallback when RevenueCat isn't configured.
  Future<SubscriptionStatus> fetch() async {
    final uid = supa.auth.currentUser!.id;
    if (_rc.isConfigured) {
      await _rc.configure(uid);
      final info = await _rc.getCustomerInfo();
      return SubscriptionStatus.fromCustomerInfo(info);
    }
    final row = await supa
        .from('subscriptions')
        .select()
        .eq('user_id', uid)
        .maybeSingle();
    if (row == null) return SubscriptionStatus.free;
    return SubscriptionStatus.fromMap(row);
  }

  Future<Offerings> getOfferings() => _rc.getOfferings();

  Future<SubscriptionStatus> purchase(Package package) async {
    final info = await _rc.purchasePackage(package);
    return SubscriptionStatus.fromCustomerInfo(info);
  }

  Future<SubscriptionStatus> restore() async {
    final info = await _rc.restorePurchases();
    return SubscriptionStatus.fromCustomerInfo(info);
  }

  /// Converts a [CustomerInfo] pushed live from RevenueCat's update
  /// listener (see [RevenueCatService.customerInfoStream]) for immediate
  /// local state — the `subscriptions` table itself is updated by
  /// RevenueCat's webhook independently of this client observing it.
  SubscriptionStatus applyCustomerInfo(CustomerInfo info) =>
      SubscriptionStatus.fromCustomerInfo(info);
}

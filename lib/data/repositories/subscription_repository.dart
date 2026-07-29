import '../../core/supabase/supabase_config.dart';
import '../models/subscription_status.dart';

class SubscriptionRepository {
  Future<SubscriptionStatus> fetch() async {
    final uid = supa.auth.currentUser!.id;
    final row = await supa.from('subscriptions').select().eq('user_id', uid).maybeSingle();
    if (row == null) return SubscriptionStatus.free;
    return SubscriptionStatus.fromMap(row);
  }

  /// Starts a 7-day free trial — no payment involved, since real billing
  /// (RevenueCat / App Store / Play Billing) isn't wired up yet. Premium
  /// access lapses on its own once `renews_at` passes; there's nothing to
  /// cancel.
  Future<SubscriptionStatus> startTrial() async {
    final uid = supa.auth.currentUser!.id;
    final renewsAt = DateTime.now().add(const Duration(days: 7));
    await supa.from('subscriptions').upsert({
      'user_id': uid,
      'tier': 'premium',
      'provider': 'trial',
      'renews_at': renewsAt.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
    return SubscriptionStatus(tier: 'premium', provider: 'trial', renewsAt: renewsAt);
  }
}

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../core/purchases/revenue_cat_service.dart';
import '../data/models/subscription_status.dart';
import '../data/repositories/subscription_repository.dart';
import 'repo_providers.dart';

final subscriptionRepositoryProvider =
    Provider((ref) => SubscriptionRepository());

class SubscriptionNotifier extends AsyncNotifier<SubscriptionStatus> {
  @override
  Future<SubscriptionStatus> build() async {
    ref.watch(currentUserIdProvider);
    final repo = ref.read(subscriptionRepositoryProvider);
    final status = await repo.fetch();

    // RevenueCat pushes customer info updates live (purchases, renewals,
    // restores, even ones made on another device) — stay subscribed so
    // state reflects them without waiting for the next explicit fetch.
    if (repo.isConfigured) {
      final sub = RevenueCatService.instance.customerInfoStream.listen(
        (info) => state = AsyncData(repo.applyCustomerInfo(info)),
      );
      ref.onDispose(sub.cancel);
    }
    return status;
  }

  Future<void> purchase(Package package) async {
    final status =
        await ref.read(subscriptionRepositoryProvider).purchase(package);
    state = AsyncData(status);
  }

  Future<void> restore() async {
    final status = await ref.read(subscriptionRepositoryProvider).restore();
    state = AsyncData(status);
  }
}

final subscriptionProvider =
    AsyncNotifierProvider<SubscriptionNotifier, SubscriptionStatus>(
  SubscriptionNotifier.new,
);

/// The current RevenueCat offering's packages (Monthly/Annual/etc, with
/// real store-localized pricing) — null when RevenueCat isn't configured.
final offeringsProvider = FutureProvider<Offerings?>((ref) async {
  ref.watch(currentUserIdProvider);
  final repo = ref.read(subscriptionRepositoryProvider);
  if (!repo.isConfigured) return null;
  // Ensure the SDK is configured (ties purchases to this Supabase user)
  // before asking it for offerings.
  await ref.read(subscriptionProvider.future);
  return repo.getOfferings();
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/subscription_status.dart';
import '../data/repositories/subscription_repository.dart';
import 'repo_providers.dart';

final subscriptionRepositoryProvider = Provider((ref) => SubscriptionRepository());

class SubscriptionNotifier extends AsyncNotifier<SubscriptionStatus> {
  @override
  Future<SubscriptionStatus> build() async {
    ref.watch(currentUserIdProvider);
    return ref.read(subscriptionRepositoryProvider).fetch();
  }

  Future<void> startTrial() async {
    final status = await ref.read(subscriptionRepositoryProvider).startTrial();
    state = AsyncData(status);
  }
}

final subscriptionProvider = AsyncNotifierProvider<SubscriptionNotifier, SubscriptionStatus>(
  SubscriptionNotifier.new,
);

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/insights_summary.dart';
import 'repo_providers.dart';

final insightsProvider = FutureProvider<InsightsSummary>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.read(insightsRepositoryProvider).fetchSummary();
});

import 'package:flutter/material.dart';

import 'revenue_cat_service.dart';

/// Gate a premium feature at the point of use: presents RevenueCat's
/// Paywall only if the user doesn't already have the entitlement, and
/// returns whether they're clear to proceed. Call before navigating to
/// (or unlocking) a premium-only feature:
///
/// ```dart
/// onPressed: () async {
///   if (await requirePremium(context)) {
///     if (context.mounted) context.push('/focus/setup');
///   }
/// },
/// ```
Future<bool> requirePremium(BuildContext context) async {
  final rc = RevenueCatService.instance;
  if (!rc.isConfigured) {
    // No purchases configured yet (see SETUP.md) — nobody could unlock the
    // feature even if gated, so don't lock them out of trying it.
    return true;
  }
  final result = await rc.presentPaywallIfNeeded();
  return result.granted;
}

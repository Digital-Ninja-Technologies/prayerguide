import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

/// The RevenueCat "Entitlement" identifier gating Premium features. Must
/// match the entitlement created in the RevenueCat dashboard exactly.
const kPremiumEntitlementId = 'PrayerGuide';

/// Thin wrapper around the RevenueCat SDK (+ Paywall/Customer Center UI)
/// for Prayer Guide Premium.
///
/// Needs an API key set in `.env` (see SETUP.md):
/// - `REVENUECAT_API_KEY` — a single cross-platform key. Used for
///   RevenueCat's Test Store (keys start with `test_`) while there's no
///   real Apple/Google developer account linked yet, since Test Store
///   isn't platform-specific.
/// - `REVENUECAT_IOS_API_KEY` / `REVENUECAT_ANDROID_API_KEY` — real
///   per-platform public SDK keys once App Store Connect / Play Console
///   products are linked. Only consulted if `REVENUECAT_API_KEY` is blank.
///
/// Without any key, [isConfigured] is false and every method throws a
/// clear [StateError] instead of the SDK failing mysteriously with an
/// invalid/empty key.
class RevenueCatService {
  RevenueCatService._();
  static final instance = RevenueCatService._();

  bool _configured = false;

  final _customerInfoController = StreamController<CustomerInfo>.broadcast();

  /// Live updates whenever RevenueCat's cached customer info changes —
  /// after a purchase, restore, renewal, or a background refresh. This is
  /// RevenueCat's recommended way to keep subscription state fresh instead
  /// of re-fetching manually after every action.
  Stream<CustomerInfo> get customerInfoStream => _customerInfoController.stream;

  String? get _platformApiKey {
    final shared = dotenv.env['REVENUECAT_API_KEY'];
    if (shared != null && shared.isNotEmpty) return shared;
    if (kIsWeb) return null;
    if (Platform.isIOS) return dotenv.env['REVENUECAT_IOS_API_KEY'];
    if (Platform.isAndroid) return dotenv.env['REVENUECAT_ANDROID_API_KEY'];
    return null;
  }

  bool get isConfigured => (_platformApiKey ?? '').isNotEmpty;

  /// Configures the SDK for [appUserId] (the Supabase user id, so purchases
  /// are tied to the same account across devices/reinstalls). Safe to call
  /// repeatedly — a no-op after the first successful call for this user.
  Future<void> configure(String appUserId) async {
    if (!isConfigured) return;
    if (_configured) return;
    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.warn);
    await Purchases.configure(
      PurchasesConfiguration(_platformApiKey!)..appUserID = appUserId,
    );
    Purchases.addCustomerInfoUpdateListener(_customerInfoController.add);
    _configured = true;
  }

  void _requireConfigured() {
    if (!isConfigured) {
      throw StateError(
        'In-app purchases need REVENUECAT_API_KEY (or REVENUECAT_IOS_API_KEY / REVENUECAT_ANDROID_API_KEY) set in .env — see SETUP.md.',
      );
    }
  }

  Future<Offerings> getOfferings() async {
    _requireConfigured();
    return Purchases.getOfferings();
  }

  Future<CustomerInfo> getCustomerInfo() async {
    _requireConfigured();
    return Purchases.getCustomerInfo();
  }

  Future<CustomerInfo> purchasePackage(Package package) async {
    _requireConfigured();
    return Purchases.purchasePackage(package);
  }

  Future<CustomerInfo> restorePurchases() async {
    _requireConfigured();
    return Purchases.restorePurchases();
  }

  bool isPremiumActive(CustomerInfo info) =>
      info.entitlements.active.containsKey(kPremiumEntitlementId);

  /// Presents RevenueCat's prebuilt Paywall only if the user doesn't
  /// already have [kPremiumEntitlementId] active — the standard way to
  /// gate a premium feature at the point of use. Returns the outcome so
  /// the caller can decide whether to proceed (e.g. `result.granted`).
  Future<PaywallResult> presentPaywallIfNeeded() async {
    _requireConfigured();
    return RevenueCatUI.presentPaywallIfNeeded(kPremiumEntitlementId);
  }

  /// Presents RevenueCat's Customer Center — self-serve subscription
  /// management (cancel, change plan, contact support), configured from
  /// the RevenueCat dashboard. Sensible entry point: a "Manage
  /// subscription" action shown once the user is already subscribed.
  Future<void> presentCustomerCenter() async {
    _requireConfigured();
    await RevenueCatUI.presentCustomerCenter();
  }

  void dispose() {
    Purchases.removeCustomerInfoUpdateListener(_customerInfoController.add);
    _customerInfoController.close();
  }
}

extension PaywallResultX on PaywallResult {
  /// True when the paywall's outcome leaves the user entitled: they either
  /// already had access ([PaywallResult.notPresented]), just purchased, or
  /// just restored a prior purchase.
  bool get granted =>
      this == PaywallResult.notPresented ||
      this == PaywallResult.purchased ||
      this == PaywallResult.restored;
}

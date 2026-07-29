import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../core/purchases/revenue_cat_service.dart';
import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../data/models/subscription_status.dart';
import '../../state/subscription_provider.dart';
import '../../widgets/pg_button.dart';

const _benefits = [
  'Unlimited prayer companions',
  'Offline Audio Bible',
  'Growth insights',
  'Full Focus Mode & extra streak freezes',
  'Premium devotionals & reading plans',
];

class UpgradeScreen extends ConsumerStatefulWidget {
  const UpgradeScreen({super.key});

  @override
  ConsumerState<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends ConsumerState<UpgradeScreen> {
  Package? _selected;
  bool _working = false;
  String? _error;

  Future<void> _purchase() async {
    final package = _selected;
    if (package == null) return;
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      await ref.read(subscriptionProvider.notifier).purchase(package);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('StateError: ', ''));
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _restore() async {
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      await ref.read(subscriptionProvider.notifier).restore();
      final status = ref.read(subscriptionProvider).valueOrNull;
      if (!mounted) return;
      if (status != null && status.isActive) {
        context.pop();
      } else {
        setState(
            () => _error = 'No previous purchase was found for this account.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('StateError: ', ''));
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final subAsync = ref.watch(subscriptionProvider);
    final sub = subAsync.valueOrNull;
    final offeringsAsync = ref.watch(offeringsProvider);
    final packages = offeringsAsync.valueOrNull?.current?.availablePackages ??
        const <Package>[];
    final monthly = _findPackage(packages, PackageType.monthly);
    final annual = _findPackage(packages, PackageType.annual);
    final configured = offeringsAsync.hasValue && offeringsAsync.value != null;

    if (configured &&
        _selected == null &&
        (monthly != null || annual != null)) {
      _selected = annual ?? monthly;
    }

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
              center: const Alignment(0, -1),
              radius: 1.1,
              colors: [c.amberSoft, Colors.transparent]),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 10, 20, 0),
                  child: IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    style: IconButton.styleFrom(
                      backgroundColor: c.surface,
                      side: BorderSide(color: c.line),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(26, 6, 26, 20),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors: [c.amber, const Color(0xFF8A5A1A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.workspace_premium_outlined,
                            size: 30, color: Color(0xFF2A1A05)),
                      ),
                      Text('Prayer Guide Premium',
                          style:
                              PgText.serif(size: 28, weight: FontWeight.w600),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      Text(
                          'Go deeper — for the seasons that ask more of your faith.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14.5, height: 1.6, color: c.dim)),
                      const SizedBox(height: 24),
                      if (sub != null && sub.isActive) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                              color: c.tealSoft,
                              border: Border.all(color: c.teal),
                              borderRadius: BorderRadius.circular(16)),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_outline_rounded,
                                  size: 20, color: c.teal),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _activeStatusMessage(sub),
                                  style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: c.teal),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      Column(
                        children: [
                          for (final b in _benefits)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Icon(Icons.check_rounded,
                                      size: 20, color: c.teal),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: Text(b,
                                          style:
                                              const TextStyle(fontSize: 14.5))),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _PlanCard(
                              label: 'Monthly',
                              price:
                                  monthly?.storeProduct.priceString ?? '\$4.99',
                              caption: 'per month',
                              selected: configured &&
                                  _selected?.identifier == monthly?.identifier,
                              enabled: configured && monthly != null,
                              onTap: monthly == null
                                  ? null
                                  : () => setState(() => _selected = monthly),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                _PlanCard(
                                  label: 'Annual',
                                  price: annual?.storeProduct.priceString ??
                                      '\$50.90',
                                  caption: annual != null
                                      ? _perMonth(annual)
                                      : '\$4.24/month',
                                  highlighted: true,
                                  selected: configured &&
                                      _selected?.identifier ==
                                          annual?.identifier,
                                  enabled: configured && annual != null,
                                  onTap: annual == null
                                      ? null
                                      : () =>
                                          setState(() => _selected = annual),
                                ),
                                Positioned(
                                  top: -10,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(
                                          color: c.teal,
                                          borderRadius:
                                              BorderRadius.circular(100)),
                                      child: Text(
                                          _savingsLabel(monthly, annual),
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: c.onTeal)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (!configured) ...[
                        const SizedBox(height: 12),
                        Text(
                          "In-app purchases aren't configured for this build yet (needs a RevenueCat project — see SETUP.md). These prices are a preview.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 11.5, color: c.faint, height: 1.5),
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12.5, color: c.danger)),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 12, 26, 30),
                child: Column(
                  children: [
                    if (sub != null && sub.isActive)
                      PgButton(
                          label: 'Continue',
                          variant: PgButtonVariant.secondaryAmber,
                          onPressed: () => context.pop())
                    else
                      PgButton(
                        label: _working ? 'Please wait…' : 'Subscribe',
                        variant: PgButtonVariant.secondaryAmber,
                        onPressed:
                            (!configured || _working || _selected == null)
                                ? null
                                : _purchase,
                      ),
                    const SizedBox(height: 10),
                    if (sub == null || !sub.isActive)
                      TextButton(
                        onPressed: _working ? null : _restore,
                        child: Text('Restore purchases',
                            style: TextStyle(
                                fontSize: 12.5,
                                color: c.dim,
                                fontWeight: FontWeight.w600)),
                      )
                    else if (RevenueCatService.instance.isConfigured)
                      TextButton(
                        onPressed: () =>
                            RevenueCatService.instance.presentCustomerCenter(),
                        child: Text('Manage subscription',
                            style: TextStyle(
                                fontSize: 12.5,
                                color: c.dim,
                                fontWeight: FontWeight.w600)),
                      )
                    else
                      Text(
                          'Manage your subscription from the App Store or Play Store.',
                          style: TextStyle(fontSize: 11.5, color: c.faint)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Package? _findPackage(List<Package> packages, PackageType type) {
    for (final p in packages) {
      if (p.packageType == type) return p;
    }
    return null;
  }

  String _perMonth(Package annual) {
    final price = annual.storeProduct.price;
    final currency = annual.storeProduct.currencyCode;
    final perMonth = price / 12;
    return '${NumberFormat.simpleCurrency(name: currency).format(perMonth)}/month';
  }

  /// Computed from the real store prices whenever both packages are known,
  /// so this always reflects whatever the Annual product is actually priced
  /// at (target: 15% below Monthly × 12 — see SETUP.md) rather than a
  /// number that can drift out of sync with App Store Connect/Play Console.
  String _savingsLabel(Package? monthly, Package? annual) {
    if (monthly != null && annual != null) {
      final fullYear = monthly.storeProduct.price * 12;
      final pct = ((1 - annual.storeProduct.price / fullYear) * 100).round();
      return 'SAVE $pct%';
    }
    return 'SAVE 15%';
  }

  String _activeStatusMessage(SubscriptionStatus sub) {
    if (sub.isTrial && sub.renewsAt != null) {
      return 'Your free trial is active until ${DateFormat('MMM d').format(sub.renewsAt!)}.';
    }
    if (!sub.willRenew && sub.renewsAt != null) {
      return "Premium is active until ${DateFormat('MMM d').format(sub.renewsAt!)} (won't renew).";
    }
    if (sub.renewsAt != null) {
      return 'Premium renews ${DateFormat('MMM d').format(sub.renewsAt!)}.';
    }
    return 'Premium is active.';
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.label,
    required this.price,
    required this.caption,
    required this.selected,
    required this.enabled,
    required this.onTap,
    this.highlighted = false,
  });
  final String label;
  final String price;
  final String caption;
  final bool selected;
  final bool enabled;
  final bool highlighted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final borderColor = selected ? c.teal : c.line;
    final bg = highlighted ? c.tealSoft : c.surface;
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: borderColor, width: selected ? 2 : 1),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: highlighted ? c.teal : c.dim)),
              const SizedBox(height: 6),
              Text(price,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800)),
              Text(caption, style: TextStyle(fontSize: 11.5, color: c.faint)),
            ],
          ),
        ),
      ),
    );
  }
}

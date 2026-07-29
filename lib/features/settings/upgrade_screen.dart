import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
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
  bool _starting = false;

  Future<void> _startTrial() async {
    setState(() => _starting = true);
    try {
      await ref.read(subscriptionProvider.notifier).startTrial();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not start your trial: $e')));
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final subAsync = ref.watch(subscriptionProvider);
    final sub = subAsync.valueOrNull;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(center: const Alignment(0, -1), radius: 1.1, colors: [c.amberSoft, Colors.transparent]),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                          gradient: LinearGradient(colors: [c.amber, const Color(0xFF8A5A1A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.workspace_premium_outlined, size: 30, color: Color(0xFF2A1A05)),
                      ),
                      Text('Prayer Guide Premium', style: PgText.serif(size: 28, weight: FontWeight.w600), textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      Text('Go deeper — for the seasons that ask more of your faith.',
                          textAlign: TextAlign.center, style: TextStyle(fontSize: 14.5, height: 1.6, color: c.dim)),
                      const SizedBox(height: 24),
                      if (sub != null && sub.isActive) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration:
                              BoxDecoration(color: c.tealSoft, border: Border.all(color: c.teal), borderRadius: BorderRadius.circular(16)),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_outline_rounded, size: 20, color: c.teal),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  sub.isTrial && sub.renewsAt != null
                                      ? 'Your free trial is active until ${DateFormat('MMM d').format(sub.renewsAt!)}.'
                                      : 'Premium is active.',
                                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: c.teal),
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
                                  Icon(Icons.check_rounded, size: 20, color: c.teal),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(b, style: const TextStyle(fontSize: 14.5))),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(18)),
                              child: Column(
                                children: [
                                  Text('Monthly', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: c.dim)),
                                  const SizedBox(height: 6),
                                  const Text('\$4.99', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                                  Text('per month', style: TextStyle(fontSize: 11.5, color: c.faint)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(color: c.tealSoft, border: Border.all(color: c.teal, width: 2), borderRadius: BorderRadius.circular(18)),
                                  child: Column(
                                    children: [
                                      Text('Annual', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: c.teal)),
                                      const SizedBox(height: 6),
                                      const Text('\$39.99', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                                      Text('\$3.33/month', style: TextStyle(fontSize: 11.5, color: c.faint)),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: -10,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(color: c.teal, borderRadius: BorderRadius.circular(100)),
                                      child: Text('SAVE 33%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: c.onTeal)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (sub != null && sub.isActive) ...[
                        const SizedBox(height: 12),
                        Text(
                          'These are the prices when subscriptions launch — checkout isn\'t wired up yet, so your trial won\'t auto-renew into one.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11.5, color: c.faint, height: 1.5),
                        ),
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
                      PgButton(label: 'Enjoy your trial', variant: PgButtonVariant.secondaryAmber, onPressed: () => context.pop())
                    else
                      PgButton(
                        label: _starting ? 'Starting…' : 'Start 7-day free trial',
                        variant: PgButtonVariant.secondaryAmber,
                        onPressed: _starting ? null : _startTrial,
                      ),
                    const SizedBox(height: 10),
                    Text(
                      sub != null && sub.isActive ? 'No payment was collected for this trial.' : 'No payment required · Cancel anytime',
                      style: TextStyle(fontSize: 11.5, color: c.faint),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

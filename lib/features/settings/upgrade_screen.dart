import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../widgets/pg_button.dart';

const _benefits = [
  'Unlimited prayer companions',
  'Offline Audio Bible',
  'Growth insights',
  'Full Focus Mode & extra streak freezes',
  'Premium devotionals & reading plans',
];

class UpgradeScreen extends StatelessWidget {
  const UpgradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
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
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                  color: c.surface,
                                  border: Border.all(color: c.line),
                                  borderRadius: BorderRadius.circular(18)),
                              child: Column(
                                children: [
                                  Text('Monthly',
                                      style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: c.dim)),
                                  const SizedBox(height: 6),
                                  const Text('\$4.99',
                                      style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800)),
                                  Text('per month',
                                      style: TextStyle(
                                          fontSize: 11.5, color: c.faint)),
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
                                  decoration: BoxDecoration(
                                      color: c.tealSoft,
                                      border:
                                          Border.all(color: c.teal, width: 2),
                                      borderRadius: BorderRadius.circular(18)),
                                  child: Column(
                                    children: [
                                      Text('Annual',
                                          style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              color: c.teal)),
                                      const SizedBox(height: 6),
                                      const Text('\$39.99',
                                          style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w800)),
                                      Text('\$3.33/month',
                                          style: TextStyle(
                                              fontSize: 11.5, color: c.faint)),
                                    ],
                                  ),
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
                                      child: Text('SAVE 33%',
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
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 12, 26, 30),
                child: Column(
                  children: [
                    PgButton(
                      label: 'Start 7-day free trial',
                      variant: PgButtonVariant.secondaryAmber,
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(height: 10),
                    Text('Cancel anytime · Restore purchase',
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
}

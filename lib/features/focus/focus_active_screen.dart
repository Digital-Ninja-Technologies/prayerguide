import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pg_text.dart';
import '../../state/focus_provider.dart';

class FocusActiveScreen extends ConsumerStatefulWidget {
  const FocusActiveScreen({super.key});

  @override
  ConsumerState<FocusActiveScreen> createState() => _FocusActiveScreenState();
}

class _FocusActiveScreenState extends ConsumerState<FocusActiveScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _endFocus() async {
    await ref.read(focusProvider.notifier).end();
    if (mounted) context.pop();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(focusProvider).valueOrNull;
    final elapsed = session == null ? Duration.zero : DateTime.now().difference(session.startedAt);
    final isGentle = session?.mode != 'full';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(center: Alignment(0, -0.4), radius: 1.1, colors: [Color(0xFF12201D), Color(0xFF080D0C)]),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.32),
                    radius: 0.9,
                    colors: [const Color(0xFF5BC2B3).withValues(alpha: .14), Colors.transparent],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: .12))),
                            alignment: Alignment.center,
                            child: Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(colors: [const Color(0xFF5BC2B3).withValues(alpha: .35), Colors.transparent]),
                              ),
                            ),
                          ),
                          const SizedBox(height: 26),
                          Text(
                            'FOCUS MODE · ${isGentle ? 'GENTLE' : 'FULL BLOCK'}',
                            style: PgText.sans(size: 11, letterSpacing: 3, weight: FontWeight.w600, color: const Color(0xFF5BC2B3)),
                          ),
                          const SizedBox(height: 16),
                          Text("You're in prayer.",
                              textAlign: TextAlign.center,
                              style: PgText.serif(size: 30, weight: FontWeight.w600, height: 1.3, color: const Color(0xFFECEAE3))),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: 250,
                            child: Text(
                              "Notifications are paused. Return when you're ready — no rush, no guilt.",
                              textAlign: TextAlign.center,
                              style: PgText.sans(size: 16, height: 1.6, color: const Color(0xFF9AA8A3)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(_fmt(elapsed), style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w300, color: Color(0xFFECEAE3))),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _endFocus,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5BC2B3),
                              foregroundColor: const Color(0xFF052019),
                              padding: const EdgeInsets.all(16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('End focus & return', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _endFocus,
                          child: const Text('I need to step out (emergency bypass)',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64726E))),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

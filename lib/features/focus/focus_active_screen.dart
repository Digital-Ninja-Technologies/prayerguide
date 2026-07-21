import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pg_text.dart';

class FocusActiveScreen extends StatelessWidget {
  const FocusActiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                    colors: [const Color(0xFF5BC2B3).withOpacity(.14), Colors.transparent],
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
                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(.12))),
                            alignment: Alignment.center,
                            child: Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(colors: [const Color(0xFF5BC2B3).withOpacity(.35), Colors.transparent]),
                              ),
                            ),
                          ),
                          const SizedBox(height: 26),
                          Text('FOCUS MODE · GENTLE',
                              style: PgText.sans(size: 11, letterSpacing: 3, weight: FontWeight.w600, color: const Color(0xFF5BC2B3))),
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
                          const Text('7:42', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w300, color: Color(0xFFECEAE3))),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => context.pop(),
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
                          onPressed: () => context.pop(),
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

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../widgets/pg_back_button.dart';

class TogetherScreen extends StatelessWidget {
  const TogetherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(center: const Alignment(0, -0.5), radius: 1, colors: [c.tealSoft, Colors.transparent]),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      PgBackButton(icon: Icons.close_rounded, onTap: () => context.pop()),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: c.tealSoft, borderRadius: BorderRadius.circular(100)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: c.teal, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text('LIVE TOGETHER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: c.teal)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 38),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 52,
                          child: Stack(
                            children: [
                              _Avatar(letter: 'S', colors: [c.teal, c.tealDeep], fg: c.onTeal),
                              Positioned(
                                left: 40,
                                child: _Avatar(letter: 'D', colors: [c.amber, const Color(0xFF8A5A1A)], fg: c.onAmber),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 26),
                        const Text('6:20', style: TextStyle(fontSize: 52, fontWeight: FontWeight.w300)),
                        const SizedBox(height: 26),
                        Container(
                          padding: const EdgeInsets.all(18),
                          constraints: const BoxConstraints(maxWidth: 280),
                          decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(18)),
                          child: Column(
                            children: [
                              Text('PRAYING TOGETHER',
                                  style: PgText.sans(size: 11, weight: FontWeight.w800, color: c.teal, letterSpacing: 1)),
                              const SizedBox(height: 8),
                              Text("Bear ye one another's burdens, and so fulfil the law of Christ.",
                                  textAlign: TextAlign.center, style: PgText.serif(size: 17, height: 1.5)),
                              const SizedBox(height: 8),
                              Text('Galatians 6:2', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: c.amber)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 34),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: c.line2),
                        padding: const EdgeInsets.all(15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text('Leave session', style: TextStyle(color: c.dim, fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.letter, required this.colors, required this.fg});
  final String letter;
  final List<Color> colors;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        border: Border.all(color: c.bg, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(letter, style: TextStyle(fontWeight: FontWeight.w800, color: fg)),
    );
  }
}

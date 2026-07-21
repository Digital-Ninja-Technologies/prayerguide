import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pg_colors.dart';
import '../../widgets/pg_back_button.dart';

class FastingScreen extends StatelessWidget {
  const FastingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(center: const Alignment(0, -0.6), radius: 1, colors: [c.amberSoft, Colors.transparent]),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
                  child: Row(
                    children: [
                      PgBackButton(onTap: () => context.pop()),
                      const SizedBox(width: 12),
                      Text('FASTING', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.dim, letterSpacing: .5)),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('SUNRISE TO SUNSET',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.amber, letterSpacing: 1)),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 250,
                          height: 250,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: const Size(250, 250),
                                painter: _RingPainter(progress: 7.2 / 12, track: c.line2, color: c.amber),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('7h 12m', style: TextStyle(fontSize: 44, fontWeight: FontWeight.w300)),
                                  const SizedBox(height: 4),
                                  Text('of 12h · 5h left', style: TextStyle(fontSize: 12.5, color: c.dim, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 34),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _StatBox(value: '3', label: 'Prayer sessions')),
                          const SizedBox(width: 12),
                          Expanded(child: _StatBox(value: '2', label: 'Journal notes')),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => context.pop(),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: c.line2),
                            padding: const EdgeInsets.all(15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text('End fast', style: TextStyle(color: c.dim, fontSize: 15, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
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

class _StatBox extends StatelessWidget {
  const _StatBox({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          Text(label, style: TextStyle(fontSize: 11.5, color: c.dim)),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.track, required this.color});
  final double progress;
  final Color track;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 3;
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, 2 * math.pi * progress, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.progress != progress;
}

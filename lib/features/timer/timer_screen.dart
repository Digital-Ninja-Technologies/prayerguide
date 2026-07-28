import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../state/profile_provider.dart';
import '../../widgets/pg_back_button.dart';
import '../../widgets/pg_button.dart';
import '../../widgets/pg_pill.dart';

class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({super.key, this.category, this.presetMinutes});
  final String? category;
  final int? presetMinutes;

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> {
  late final String _category = widget.category ?? 'Thanksgiving';
  late int _preset = widget.presetMinutes ?? 10;
  late int _remaining = _preset * 60;
  bool _running = false;
  bool _done = false;
  String? _ambience;
  Timer? _timer;

  static const _presets = [5, 10, 15, 30, 60];

  String get _label {
    final m = _remaining ~/ 60;
    final s = _remaining % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  void _setPreset(int min) {
    _timer?.cancel();
    setState(() {
      _preset = min;
      _remaining = min * 60;
      _running = false;
      _done = false;
    });
  }

  void _toggleRun() {
    if (_done) return;
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        if (_remaining <= 1) {
          t.cancel();
          _remaining = 0;
          _running = false;
          _done = true;
        } else {
          _remaining--;
        }
      });
    });
  }

  Future<void> _finish() async {
    final duration = _preset * 60;
    await ref.read(profileProvider.notifier).completeSession(
          durationSeconds: duration,
          category: _category,
        );
    if (mounted) context.go('/home');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final total = _preset * 60;
    final circumference = 2 * math.pi * 120;
    final offset = circumference * (1 - _remaining / total);
    final state = _done ? 'Complete' : (_running ? 'In prayer' : (_remaining < total ? 'Paused' : 'Ready'));
    final nextStreak = (ref.watch(profileProvider).valueOrNull?.streakCount ?? 0) + 1;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.5),
                  radius: 1,
                  colors: [c.tealSoft, Colors.transparent],
                ),
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
                      Text(_category.toUpperCase(),
                          style: PgText.sans(size: 13, weight: FontWeight.w700, color: c.dim, letterSpacing: .5)),
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
                          width: 280,
                          height: 280,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 280,
                                height: 280,
                                child: CustomPaint(
                                  painter: _RingPainter(
                                    progress: total == 0 ? 0 : 1 - (offset / circumference),
                                    track: c.line2,
                                    color: c.teal,
                                  ),
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_label,
                                      style: const TextStyle(
                                          fontSize: 58, fontWeight: FontWeight.w300, letterSpacing: 1)),
                                  const SizedBox(height: 6),
                                  Text(state.toUpperCase(),
                                      style: PgText.sans(
                                          size: 12.5, weight: FontWeight.w700, color: c.dim, letterSpacing: 2)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 34),
                        Material(
                          color: c.teal,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _toggleRun,
                            child: SizedBox(
                              width: 74,
                              height: 74,
                              child: Icon(
                                _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: c.onTeal,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 30),
                  child: Column(
                    children: [
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final p in _presets)
                            PgPill(label: '$p', active: _preset == p, onTap: () => _setPreset(p)),
                          PgPill(
                            label: 'Custom',
                            active: !_presets.contains(_preset),
                            onTap: () => _setPreset(45),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (final a in const [('rain', 'Rain'), ('ocean', 'Ocean'), ('instrumental', 'Instrumental')])
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.5),
                              child: PgPill(
                                label: a.$2,
                                active: _ambience == a.$1,
                                activeColor: c.tealSoft,
                                activeFg: c.teal,
                                onTap: () => setState(() => _ambience = _ambience == a.$1 ? null : a.$1),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      PgButton(
                        label: 'Focus Mode · silence distractions',
                        variant: PgButtonVariant.outline,
                        icon: Icon(Icons.timer_outlined, size: 17, color: c.teal),
                        onPressed: () => context.push('/focus/setup'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_done)
            Positioned.fill(
              child: Container(
                color: c.bg,
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(color: c.tealSoft, shape: BoxShape.circle, border: Border.all(color: c.line)),
                      child: Icon(Icons.check_rounded, size: 46, color: c.teal),
                    ),
                    const SizedBox(height: 22),
                    Text('Well prayed.', style: PgText.serif(size: 27, weight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 250,
                      child: Text(
                        'You spent time with God today. Your streak continues — no pressure, only presence.',
                        textAlign: TextAlign.center,
                        style: PgText.sans(size: 15, height: 1.6, color: c.dim),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(color: c.amberSoft, borderRadius: BorderRadius.circular(100)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_fire_department_rounded, size: 18, color: c.amber),
                          const SizedBox(width: 9),
                          Text('$nextStreak day streak',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: c.amber)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    PgButton(label: 'Done', expand: false, onPressed: _finish),
                  ],
                ),
              ),
            ),
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
      ..strokeWidth = 5;
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0, 1),
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.progress != progress;
}

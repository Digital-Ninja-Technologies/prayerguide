import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../state/fasting_provider.dart';
import '../../widgets/pg_back_button.dart';
import '../../widgets/pg_button.dart';
import '../../widgets/pg_error_state.dart';
import '../../widgets/pg_pill.dart';

class FastingScreen extends ConsumerStatefulWidget {
  const FastingScreen({super.key});

  @override
  ConsumerState<FastingScreen> createState() => _FastingScreenState();
}

class _FastingScreenState extends ConsumerState<FastingScreen> {
  Timer? _ticker;
  double _selectedHours = 16;

  @override
  void initState() {
    super.initState();
    // Refreshes the elapsed/remaining labels while a fast is active. Cheap —
    // just a rebuild, no network call.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fastingAsync = ref.watch(fastingProvider);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                    center: const Alignment(0, -0.6),
                    radius: 1,
                    colors: [c.amberSoft, Colors.transparent]),
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
                      Text('FASTING',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: c.dim,
                              letterSpacing: .5)),
                    ],
                  ),
                ),
                Expanded(
                  child: fastingAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Center(
                      child: PgErrorState(
                          error: e,
                          onRetry: () => ref.invalidate(fastingProvider)),
                    ),
                    data: (fasting) => fasting.session == null
                        ? _buildStart(c)
                        : _buildActive(c, fasting),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStart(PgColors c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                  color: c.amberSoft, borderRadius: BorderRadius.circular(24)),
              child: Icon(Icons.wb_twilight_outlined, size: 36, color: c.amber),
            ),
            const SizedBox(height: 18),
            Text('Begin a fast',
                style: PgText.serif(size: 22, weight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              "Pair fasting with prayer and reflection. We'll track your time and what you pray and journal along the way.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: c.dim, height: 1.6),
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final h in const [12.0, 16.0, 24.0])
                  PgPill(
                    label: '${h.toInt()}h',
                    active: _selectedHours == h,
                    activeColor: c.amber,
                    activeFg: c.onAmber,
                    onTap: () => setState(() => _selectedHours = h),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            PgButton(
              label: 'Begin fast',
              variant: PgButtonVariant.secondaryAmber,
              onPressed: () =>
                  ref.read(fastingProvider.notifier).start(_selectedHours),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActive(PgColors c, FastingState fasting) {
    final session = fasting.session!;
    final elapsed = DateTime.now().difference(session.startedAt);
    final targetDuration =
        Duration(minutes: (session.targetHours * 60).round());
    final remaining = targetDuration - elapsed;
    final progress =
        (elapsed.inSeconds / targetDuration.inSeconds).clamp(0.0, 1.0);
    final done = remaining.inSeconds <= 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${session.targetHours.toInt()}-HOUR FAST',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: c.amber,
                        letterSpacing: 1)),
                const SizedBox(height: 6),
                SizedBox(
                  width: 250,
                  height: 250,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(250, 250),
                        painter: _RingPainter(
                            progress: progress, track: c.line2, color: c.amber),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_fmt(elapsed),
                              style: const TextStyle(
                                  fontSize: 44, fontWeight: FontWeight.w300)),
                          const SizedBox(height: 4),
                          Text(
                            done
                                ? 'Goal reached'
                                : 'of ${session.targetHours.toInt()}h · ${_fmt(remaining)} left',
                            style: TextStyle(
                                fontSize: 12.5,
                                color: c.dim,
                                fontWeight: FontWeight.w700),
                          ),
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
                  Expanded(
                      child: _StatBox(
                          value: '${fasting.prayerSessionCount}',
                          label: 'Prayer sessions')),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _StatBox(
                          value: '${fasting.journalNoteCount}',
                          label: 'Journal notes')),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => ref.read(fastingProvider.notifier).end(),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: c.line2),
                    padding: const EdgeInsets.all(15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('End fast',
                      style: TextStyle(
                          color: c.dim,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _fmt(Duration d) {
    final clamped = d.isNegative ? Duration.zero : d;
    final h = clamped.inHours;
    final m = clamped.inMinutes % 60;
    return '${h}h ${m}m';
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
      decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Text(value,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          Text(label, style: TextStyle(fontSize: 11.5, color: c.dim)),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(
      {required this.progress, required this.track, required this.color});
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
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, 2 * math.pi * progress, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

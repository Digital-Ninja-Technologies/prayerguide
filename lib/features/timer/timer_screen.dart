import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/live_activity/live_activity_service.dart';
import '../../core/notifications/notification_scheduler.dart';
import '../../core/rating/rating_prompt.dart';
import '../../core/streak/streak_share_prompt.dart';
import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../state/insights_provider.dart';
import '../../state/profile_provider.dart';
import '../../widgets/pg_back_button.dart';
import '../../widgets/pg_button.dart';
import '../../widgets/pg_pill.dart';
import '../../widgets/pg_text_field.dart';
import 'ambience_player.dart';

/// Persisted so the countdown can be reconciled against wall-clock time if
/// the app is suspended/killed while a timer is running — Dart's
/// `Timer.periodic` doesn't tick in the background, so [_remaining] alone
/// would go stale, while this stores the one thing that's always correct:
/// when the countdown actually ends.
const _sessionPrefsKey = 'active_timer_session_v1';

class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({super.key, this.category, this.presetMinutes});
  final String? category;
  final int? presetMinutes;

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen>
    with WidgetsBindingObserver {
  late final String _category = widget.category ?? 'Thanksgiving';
  late int _preset = widget.presetMinutes ?? 10;
  late int _remaining = _preset * 60;
  bool _running = false;
  bool _done = false;
  String? _ambience;
  Timer? _timer;
  final _ambiencePlayer = AmbiencePlayer();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _reconcileWithPersistedSession();
  }

  /// Runs on every app resume — recomputes where the countdown actually is
  /// from the persisted `endDate` rather than trusting [_remaining], which
  /// only ticked while the app was in the foreground. If the countdown
  /// already ran out while backgrounded, this lands on the exact same
  /// "Complete" screen state a foreground expiry would (see the `t.cancel()`
  /// branch in [_toggleRun]) — the user still taps Done to actually log the
  /// session, so background-vs-foreground expiry behave identically.
  Future<void> _reconcileWithPersistedSession() async {
    if (!_running || _done) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionPrefsKey);
    if (raw == null || !mounted) return;
    try {
      final session = jsonDecode(raw) as Map<String, dynamic>;
      if (session['isPaused'] == true) return;
      final endDate =
          DateTime.fromMillisecondsSinceEpoch(session['endDateMillis'] as int);
      final secondsLeft = endDate.difference(DateTime.now()).inSeconds;
      if (secondsLeft <= 0) {
        _timer?.cancel();
        setState(() {
          _remaining = 0;
          _running = false;
          _done = true;
        });
      } else {
        setState(() => _remaining = secondsLeft);
      }
    } catch (_) {
      // Corrupt/outdated persisted session — nothing to reconcile against.
    }
  }

  Future<void> _persistSession({
    required bool isPaused,
    required DateTime endDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _sessionPrefsKey,
      jsonEncode({
        'category': _category,
        'endDateMillis': endDate.millisecondsSinceEpoch,
        'isPaused': isPaused,
        'remainingSecondsWhenPaused': _remaining,
      }),
    );
  }

  Future<void> _clearPersistedSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionPrefsKey);
  }

  static String _formatMinutes(int min) {
    final h = min ~/ 60;
    final m = min % 60;
    if (h == 0) return '$m min';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  Future<void> _toggleAmbience(String key) async {
    if (_ambience == key) {
      setState(() => _ambience = null);
      await _ambiencePlayer.stop();
      return;
    }
    setState(() => _ambience = key);
    try {
      await _ambiencePlayer.play(key);
    } catch (e) {
      if (!mounted) return;
      setState(() => _ambience = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't play that track: $e")),
      );
    }
  }

  String get _label {
    final h = _remaining ~/ 3600;
    final m = (_remaining % 3600) ~/ 60;
    final s = _remaining % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  void _setPreset(int min) {
    _timer?.cancel();
    final wasRunning = _running;
    setState(() {
      _preset = min;
      _remaining = min * 60;
      _running = false;
      _done = false;
    });
    if (wasRunning) {
      LiveActivityService.instance.end();
      NotificationScheduler.instance.cancelTimerCompletion();
      _clearPersistedSession();
    }
  }

  Future<void> _promptCustomDuration() async {
    final c = context.colors;
    final hoursCtrl = TextEditingController(text: '${_preset ~/ 60}');
    final minutesCtrl = TextEditingController(text: '${_preset % 60}');
    final total = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Custom duration'),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('HOURS',
                      style: PgText.sans(
                          size: 11,
                          weight: FontWeight.w700,
                          color: c.dim,
                          letterSpacing: 1)),
                  const SizedBox(height: 6),
                  PgTextField(
                      controller: hoursCtrl,
                      keyboardType: TextInputType.number),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('MINUTES',
                      style: PgText.sans(
                          size: 11,
                          weight: FontWeight.w700,
                          color: c.dim,
                          letterSpacing: 1)),
                  const SizedBox(height: 6),
                  PgTextField(
                      controller: minutesCtrl,
                      keyboardType: TextInputType.number),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final h = int.tryParse(hoursCtrl.text) ?? 0;
              final m = int.tryParse(minutesCtrl.text) ?? 0;
              Navigator.of(context).pop((h * 60 + m).clamp(1, 599));
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
    if (total != null) _setPreset(total);
  }

  void _toggleRun() {
    if (_done) return;
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      final endDate = DateTime.now().add(Duration(seconds: _remaining));
      LiveActivityService.instance.updatePaused(
        isPaused: true,
        remainingSeconds: _remaining,
        endDate: endDate,
      );
      NotificationScheduler.instance.cancelTimerCompletion();
      _persistSession(isPaused: true, endDate: endDate);
      return;
    }
    final firstStart = _remaining == _preset * 60;
    setState(() => _running = true);
    final endDate = DateTime.now().add(Duration(seconds: _remaining));
    if (firstStart) {
      LiveActivityService.instance.start(category: _category, endDate: endDate);
    } else {
      LiveActivityService.instance
          .updatePaused(isPaused: false, remainingSeconds: _remaining, endDate: endDate);
    }
    NotificationScheduler.instance
        .scheduleTimerCompletion(endDate: endDate, category: _category);
    _persistSession(isPaused: false, endDate: endDate);
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
    await LiveActivityService.instance.end();
    await NotificationScheduler.instance.cancelTimerCompletion();
    await _clearPersistedSession();
    await ref.read(profileProvider.notifier).completeSession(
          durationSeconds: duration,
          category: _category,
        );
    final updatedProfile = ref.read(profileProvider).valueOrNull;
    final streakCount = updatedProfile?.streakCount ?? 0;
    if (mounted) {
      await maybeShowRatingPrompt(context, streakCount: streakCount);
    }
    if (mounted) {
      final weekTimeLabel =
          ref.read(insightsProvider).valueOrNull?.totalTimeLabel ?? '0m';
      await maybeShowStreakSharePrompt(
        context,
        streakCount: streakCount,
        longestStreak: updatedProfile?.longestStreak ?? streakCount,
        weekTimeLabel: weekTimeLabel,
      );
    }
    if (mounted) context.go('/home');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _ambiencePlayer.dispose();
    LiveActivityService.instance.end();
    if (_running && !_done) {
      // Screen closed mid-run (the X button, not the Done flow) — nothing
      // else would ever cancel the scheduled completion notification or
      // clear the persisted session otherwise, since both are keyed off
      // this screen's lifecycle.
      NotificationScheduler.instance.cancelTimerCompletion();
      _clearPersistedSession();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final total = _preset * 60;
    const circumference = 2 * math.pi * 120;
    final offset = circumference * (1 - _remaining / total);
    final state = _done
        ? 'Complete'
        : (_running ? 'In prayer' : (_remaining < total ? 'Paused' : 'Ready'));
    final nextStreak =
        (ref.watch(profileProvider).valueOrNull?.streakCount ?? 0) + 1;

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
                      PgBackButton(
                          icon: Icons.close_rounded,
                          onTap: () => context.pop()),
                      Text(_category.toUpperCase(),
                          style: PgText.sans(
                              size: 13,
                              weight: FontWeight.w700,
                              color: c.dim,
                              letterSpacing: .5)),
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
                                    progress: total == 0
                                        ? 0
                                        : 1 - (offset / circumference),
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
                                          fontSize: 58,
                                          fontWeight: FontWeight.w300,
                                          letterSpacing: 1)),
                                  const SizedBox(height: 6),
                                  Text(state.toUpperCase(),
                                      style: PgText.sans(
                                          size: 12.5,
                                          weight: FontWeight.w700,
                                          color: c.dim,
                                          letterSpacing: 2)),
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
                                _running
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('DURATION',
                              style: PgText.sans(
                                  size: 11,
                                  weight: FontWeight.w700,
                                  color: c.dim,
                                  letterSpacing: 1)),
                          GestureDetector(
                            onTap: _promptCustomDuration,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_formatMinutes(_preset),
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: c.teal)),
                                const SizedBox(width: 4),
                                Icon(Icons.edit_rounded,
                                    size: 13, color: c.teal),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: c.teal,
                          inactiveTrackColor: c.line2,
                          thumbColor: c.teal,
                          overlayColor: c.teal.withValues(alpha: .15),
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: _preset.clamp(5, 120).toDouble(),
                          min: 5,
                          max: 120,
                          divisions: 23,
                          onChanged: (v) => _setPreset(v.round()),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('5 min',
                                style: TextStyle(fontSize: 11, color: c.faint)),
                            Text('2h',
                                style: TextStyle(fontSize: 11, color: c.faint)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('AMBIENCE',
                              style: PgText.sans(
                                  size: 11,
                                  weight: FontWeight.w700,
                                  color: c.dim,
                                  letterSpacing: 1)),
                          if (_ambience != null) ...[
                            const SizedBox(width: 7),
                            _PulsingDot(color: c.teal),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (final a in const [
                            ('meditation', 'Meditation'),
                            ('silence', 'Silence'),
                            ('tenderclouds', 'Tender Clouds'),
                          ])
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4.5),
                              child: PgPill(
                                label: a.$2,
                                active: _ambience == a.$1,
                                activeColor: c.tealSoft,
                                activeFg: c.teal,
                                onTap: () => _toggleAmbience(a.$1),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      PgButton(
                        label: 'Focus Mode · silence distractions',
                        variant: PgButtonVariant.outline,
                        icon:
                            Icon(Icons.timer_outlined, size: 17, color: c.teal),
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
                      decoration: BoxDecoration(
                          color: c.tealSoft,
                          shape: BoxShape.circle,
                          border: Border.all(color: c.line)),
                      child: Icon(Icons.check_rounded, size: 46, color: c.teal),
                    ),
                    const SizedBox(height: 22),
                    Text('Well prayed.',
                        style: PgText.serif(size: 27, weight: FontWeight.w600)),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                          color: c.amberSoft,
                          borderRadius: BorderRadius.circular(100)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_fire_department_rounded,
                              size: 18, color: c.amber),
                          const SizedBox(width: 9),
                          Text('$nextStreak day streak',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: c.amber)),
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

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});
  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.25, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: Container(
          width: 7,
          height: 7,
          decoration:
              BoxDecoration(color: widget.color, shape: BoxShape.circle)),
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
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

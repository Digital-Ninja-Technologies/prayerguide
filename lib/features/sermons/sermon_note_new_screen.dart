import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/audio/sermon_recorder.dart';
import '../../core/theme/pg_colors.dart';
import '../../state/sermon_notes_provider.dart';
import '../../widgets/pg_header.dart';
import '../../widgets/pg_text_field.dart';

enum _RecordState { idle, recording, paused, stopped }

class SermonNoteNewScreen extends ConsumerStatefulWidget {
  const SermonNoteNewScreen({super.key});

  @override
  ConsumerState<SermonNoteNewScreen> createState() => _SermonNoteNewScreenState();
}

class _SermonNoteNewScreenState extends ConsumerState<SermonNoteNewScreen> {
  final _title = TextEditingController();
  final _speaker = TextEditingController();
  final _scripture = TextEditingController();
  final _notes = TextEditingController();

  final _recorder = SermonRecorder();
  _RecordState _recordState = _RecordState.idle;
  int _elapsedSeconds = 0;
  String? _audioPath;
  Timer? _ticker;

  bool _saving = false;
  String? _error;

  bool get _canRecord => !kIsWeb;

  Future<void> _toggleRecord() async {
    if (_recordState == _RecordState.idle) {
      final granted = await _recorder.hasPermission();
      if (!granted) {
        setState(() => _error = 'Microphone access is needed to record.');
        return;
      }
      await _recorder.start();
      _startTicker();
      setState(() {
        _recordState = _RecordState.recording;
        _error = null;
      });
    } else if (_recordState == _RecordState.recording) {
      await _recorder.pause();
      _ticker?.cancel();
      setState(() => _recordState = _RecordState.paused);
    } else if (_recordState == _RecordState.paused) {
      await _recorder.resume();
      _startTicker();
      setState(() => _recordState = _RecordState.recording);
    }
  }

  Future<void> _stopRecording() async {
    _ticker?.cancel();
    final path = await _recorder.stop();
    setState(() {
      _audioPath = path;
      _recordState = _RecordState.stopped;
    });
  }

  Future<void> _discardRecording() async {
    _ticker?.cancel();
    if (_recordState == _RecordState.recording || _recordState == _RecordState.paused) {
      await _recorder.cancel();
    }
    setState(() {
      _audioPath = null;
      _elapsedSeconds = 0;
      _recordState = _RecordState.idle;
    });
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsedSeconds++);
    });
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Give this sermon a title.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(sermonNotesProvider.notifier).add(
            title: title,
            speaker: _speaker.text.trim().isEmpty ? null : _speaker.text.trim(),
            scriptureRef: _scripture.text.trim().isEmpty ? null : _scripture.text.trim(),
            notes: _notes.text.trim(),
            audioFilePath: _audioPath,
            audioDurationSeconds: _audioPath == null ? null : _elapsedSeconds,
          );
      if (mounted) context.pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String get _label {
    final m = _elapsedSeconds ~/ 60;
    final s = _elapsedSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _ticker?.cancel();
    if (_recordState == _RecordState.recording || _recordState == _RecordState.paused) {
      _recorder.cancel();
    }
    _recorder.dispose();
    _title.dispose();
    _speaker.dispose();
    _scripture.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final recording = _recordState == _RecordState.recording;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
              child: PgHeader(
                title: 'New sermon note',
                onBack: () => context.pop(),
                trailing: TextButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Saving…' : 'Save', style: TextStyle(color: c.teal, fontWeight: FontWeight.w800, fontSize: 14)),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PgTextField(controller: _title, hint: 'Sermon title', fontWeight: FontWeight.w700),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: PgTextField(controller: _speaker, hint: 'Speaker (optional)')),
                        const SizedBox(width: 10),
                        Expanded(child: PgTextField(controller: _scripture, hint: 'Scripture ref (optional)')),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (_canRecord) _RecordPanel(
                      state: _recordState,
                      label: _label,
                      onToggle: _toggleRecord,
                      onStop: _stopRecording,
                      onDiscard: _discardRecording,
                    ) else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(14)),
                        child: Text(
                          "Audio recording isn't available in this build — you can still type notes below.",
                          style: TextStyle(fontSize: 12.5, color: c.faint),
                        ),
                      ),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(_error!, style: TextStyle(color: c.danger, fontSize: 12.5)),
                    ],
                    const SizedBox(height: 18),
                    Text('NOTES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1, color: c.dim)),
                    const SizedBox(height: 10),
                    PgTextField(
                      controller: _notes,
                      hint: recording ? 'Type along as you listen…' : 'Write your notes…',
                      maxLines: 14,
                      serif: true,
                      fontWeight: FontWeight.w400,
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

class _RecordPanel extends StatelessWidget {
  const _RecordPanel({
    required this.state,
    required this.label,
    required this.onToggle,
    required this.onStop,
    required this.onDiscard,
  });

  final _RecordState state;
  final String label;
  final VoidCallback onToggle;
  final VoidCallback onStop;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final active = state == _RecordState.recording || state == _RecordState.paused;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (state == _RecordState.recording) ...[
                const _PulsingDot(),
                const SizedBox(width: 8),
              ],
              Text(label, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w300, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            switch (state) {
              _RecordState.idle => 'Ready to record',
              _RecordState.recording => 'Recording…',
              _RecordState.paused => 'Paused',
              _RecordState.stopped => 'Recording saved to this note',
            },
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: c.dim, letterSpacing: .5),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (state != _RecordState.stopped)
                Material(
                  color: active ? c.surface2 : c.teal,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onToggle,
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: Icon(
                        state == _RecordState.recording ? Icons.pause_rounded : Icons.mic_rounded,
                        color: active ? c.text : c.onTeal,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              if (active) ...[
                const SizedBox(width: 14),
                Material(
                  color: c.danger,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onStop,
                    child: const SizedBox(width: 60, height: 60, child: Icon(Icons.stop_rounded, color: Colors.white, size: 26)),
                  ),
                ),
              ],
              if (state == _RecordState.stopped) ...[
                Icon(Icons.check_circle_rounded, color: c.teal, size: 30),
                const SizedBox(width: 10),
                TextButton(onPressed: onDiscard, child: const Text('Re-record')),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return FadeTransition(
      opacity: Tween(begin: 0.25, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: Container(width: 10, height: 10, decoration: BoxDecoration(color: c.danger, shape: BoxShape.circle)),
    );
  }
}

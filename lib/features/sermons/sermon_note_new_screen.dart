import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/audio/sermon_recorder.dart';
import '../../core/live_activity/live_activity_service.dart';
import '../../core/theme/pg_colors.dart';
import '../../state/sermon_notes_provider.dart';
import '../../widgets/pg_header.dart';
import '../../widgets/pg_text_field.dart';

enum _RecordState { idle, recording, paused }

class _Take {
  _Take({required this.path, required this.durationSeconds});
  final String path;
  final int durationSeconds;
}

const _draftPrefsKey = 'sermon_note_draft_v1';

class SermonNoteNewScreen extends ConsumerStatefulWidget {
  const SermonNoteNewScreen({super.key});

  @override
  ConsumerState<SermonNoteNewScreen> createState() =>
      _SermonNoteNewScreenState();
}

class _SermonNoteNewScreenState extends ConsumerState<SermonNoteNewScreen> {
  final _title = TextEditingController();
  final _speaker = TextEditingController();
  final _scripture = TextEditingController();
  final _notes = TextEditingController();

  final _recorder = SermonRecorder();
  _RecordState _recordState = _RecordState.idle;
  int _elapsedSeconds = 0;
  final List<_Take> _takes = [];
  Timer? _ticker;
  Timer? _draftDebounce;
  Timer? _autoSaveDebounce;

  /// Once this note has an id, it's a real row in the backend — further
  /// edits update it instead of creating a second one.
  String? _noteId;
  bool _autoSaving = false;

  bool _saving = false;
  String? _error;

  bool get _canRecord => !kIsWeb;

  @override
  void initState() {
    super.initState();
    _restoreDraft();
    for (final c in [_title, _speaker, _scripture, _notes]) {
      c.addListener(_scheduleDraftSave);
      c.addListener(_scheduleAutoSave);
    }
  }

  bool get _hasContent =>
      _title.text.trim().isNotEmpty ||
      _speaker.text.trim().isNotEmpty ||
      _scripture.text.trim().isNotEmpty ||
      _notes.text.trim().isNotEmpty ||
      _takes.isNotEmpty ||
      _noteId != null;

  void _scheduleAutoSave() {
    _autoSaveDebounce?.cancel();
    _autoSaveDebounce = Timer(const Duration(milliseconds: 800), _autoSave);
  }

  /// Creates the note on first save, then keeps it updated — so typing or
  /// recording anything is saved without waiting for an explicit Save tap,
  /// and nothing is lost if the user just backs out instead.
  Future<void> _autoSave() async {
    if (!_hasContent || _autoSaving) return;
    _autoSaving = true;
    try {
      final title = _title.text.trim();
      final speaker =
          _speaker.text.trim().isEmpty ? null : _speaker.text.trim();
      final scriptureRef =
          _scripture.text.trim().isEmpty ? null : _scripture.text.trim();
      final notes = _notes.text.trim();
      final notifier = ref.read(sermonNotesProvider.notifier);

      if (_noteId == null) {
        final pendingTakes = List<_Take>.from(_takes);
        await notifier.add(
          title: title,
          speaker: speaker,
          scriptureRef: scriptureRef,
          notes: notes,
          initialRecordingPaths: [
            for (final t in pendingTakes)
              (path: t.path, durationSeconds: t.durationSeconds),
          ],
        );
        _noteId = ref.read(sermonNotesProvider).value?.first.id;
        _takes.removeWhere(pendingTakes.contains);
      } else {
        await notifier.updateNote(
          noteId: _noteId!,
          title: title,
          speaker: speaker,
          scriptureRef: scriptureRef,
          notes: notes,
        );
        for (final t in List<_Take>.from(_takes)) {
          await notifier.addRecording(
            noteId: _noteId!,
            localFilePath: t.path,
            durationSeconds: t.durationSeconds,
          );
          _takes.remove(t);
        }
      }
      await _clearDraft();
    } catch (_) {
      // Best-effort background save — the local draft (SharedPreferences)
      // still has the latest text as a fallback, and the next debounced
      // call (or the final save-on-back) will retry.
    } finally {
      _autoSaving = false;
    }
  }

  /// Final flush used when leaving the screen (back arrow or the header's
  /// Done button) — stops any in-progress recording first so it's included,
  /// then makes sure everything typed/recorded so far is actually saved.
  Future<bool> _finishAndSave() async {
    _autoSaveDebounce?.cancel();
    if (_recordState == _RecordState.recording ||
        _recordState == _RecordState.paused) {
      await _stopRecording();
    }
    if (!_hasContent) return true;
    setState(() => _saving = true);
    try {
      await _autoSave();
      return true;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _handleBack() async {
    final ok = await _finishAndSave();
    if (mounted) context.pop(ok && _noteId != null);
  }

  Future<void> _restoreDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftPrefsKey);
    if (raw == null || !mounted) return;
    try {
      final draft = jsonDecode(raw) as Map<String, dynamic>;
      _title.text = draft['title'] as String? ?? '';
      _speaker.text = draft['speaker'] as String? ?? '';
      _scripture.text = draft['scripture'] as String? ?? '';
      _notes.text = draft['notes'] as String? ?? '';
      if (_title.text.isNotEmpty || _notes.text.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restored your unsaved draft')),
        );
      }
    } catch (_) {
      // Corrupt or outdated draft shape — ignore it rather than crash.
    }
  }

  void _scheduleDraftSave() {
    _draftDebounce?.cancel();
    _draftDebounce = Timer(const Duration(milliseconds: 500), _saveDraft);
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _draftPrefsKey,
      jsonEncode({
        'title': _title.text,
        'speaker': _speaker.text,
        'scripture': _scripture.text,
        'notes': _notes.text,
      }),
    );
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftPrefsKey);
  }

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
      final title = _title.text.trim();
      LiveActivityService.instance
          .startRecording(title: title.isEmpty ? 'Sermon note' : title);
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

  /// Stops and locks in the current take — it joins the list permanently;
  /// there's no re-record/overwrite, only starting another new take. Saves
  /// immediately (rather than waiting for the text debounce) since there's
  /// now a real recorded file worth not losing.
  Future<void> _stopRecording() async {
    _ticker?.cancel();
    LiveActivityService.instance.endRecording();
    final path = await _recorder.stop();
    if (path != null) {
      _takes.add(_Take(path: path, durationSeconds: _elapsedSeconds));
    }
    setState(() {
      _elapsedSeconds = 0;
      _recordState = _RecordState.idle;
    });
    if (path != null) await _autoSave();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsedSeconds++);
    });
  }

  Future<void> _deleteTake(int index) async {
    final take = _takes[index];
    setState(() => _takes.removeAt(index));
    try {
      await File(take.path).delete();
    } catch (_) {
      // Best-effort — a leftover temp file isn't worth surfacing to the user.
    }
  }

  String _fmt(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _draftDebounce?.cancel();
    _autoSaveDebounce?.cancel();
    if (_recordState == _RecordState.recording ||
        _recordState == _RecordState.paused) {
      _recorder.cancel();
      LiveActivityService.instance.endRecording();
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
                onBack: () => _handleBack(),
                trailing: TextButton(
                  onPressed: _saving ? null : _handleBack,
                  child: Text(_saving ? 'Saving…' : 'Done',
                      style: TextStyle(
                          color: c.teal,
                          fontWeight: FontWeight.w800,
                          fontSize: 14)),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PgTextField(
                        controller: _title,
                        hint: 'Sermon title',
                        fontWeight: FontWeight.w700),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                            child: PgTextField(
                                controller: _speaker,
                                hint: 'Speaker (optional)')),
                        const SizedBox(width: 10),
                        Expanded(
                            child: PgTextField(
                                controller: _scripture,
                                hint: 'Scripture ref (optional)')),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (_canRecord) ...[
                      _RecordPanel(
                        state: _recordState,
                        label: _fmt(_elapsedSeconds),
                        onToggle: _toggleRecord,
                        onStop: _stopRecording,
                      ),
                      if (_takes.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        for (var i = 0; i < _takes.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: _TakeRow(
                              index: i + 1,
                              durationLabel: _fmt(_takes[i].durationSeconds),
                              onDelete: () => _deleteTake(i),
                            ),
                          ),
                      ],
                    ] else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: c.surface2,
                            borderRadius: BorderRadius.circular(14)),
                        child: Text(
                          "Audio recording isn't available in this build — you can still type notes below.",
                          style: TextStyle(fontSize: 12.5, color: c.faint),
                        ),
                      ),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(_error!,
                          style: TextStyle(color: c.danger, fontSize: 12.5)),
                    ],
                    const SizedBox(height: 18),
                    Text('NOTES',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            color: c.dim)),
                    const SizedBox(height: 10),
                    PgTextField(
                      controller: _notes,
                      hint: recording
                          ? 'Type along as you listen…'
                          : 'Write your notes…',
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

class _TakeRow extends StatelessWidget {
  const _TakeRow(
      {required this.index,
      required this.durationLabel,
      required this.onDelete});
  final int index;
  final String durationLabel;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
          color: c.surface2, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: c.teal, size: 16),
          const SizedBox(width: 8),
          Text('Take $index',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: c.text)),
          const Spacer(),
          Text(durationLabel, style: TextStyle(fontSize: 12.5, color: c.dim)),
          const SizedBox(width: 10),
          InkWell(
            onTap: onDelete,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close_rounded, size: 16, color: c.faint),
            ),
          ),
        ],
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
  });

  final _RecordState state;
  final String label;
  final VoidCallback onToggle;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final active =
        state == _RecordState.recording || state == _RecordState.paused;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (state == _RecordState.recording) ...[
                const _PulsingDot(),
                const SizedBox(width: 8),
              ],
              Text(label,
                  style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            switch (state) {
              _RecordState.idle => 'Ready to record',
              _RecordState.recording => 'Recording…',
              _RecordState.paused => 'Paused',
            },
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: c.dim,
                letterSpacing: .5),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                      state == _RecordState.recording
                          ? Icons.pause_rounded
                          : Icons.mic_rounded,
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
                    child: const SizedBox(
                        width: 60,
                        height: 60,
                        child: Icon(Icons.stop_rounded,
                            color: Colors.white, size: 26)),
                  ),
                ),
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
    final c = context.colors;
    return FadeTransition(
      opacity: Tween(begin: 0.25, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: c.danger, shape: BoxShape.circle)),
    );
  }
}

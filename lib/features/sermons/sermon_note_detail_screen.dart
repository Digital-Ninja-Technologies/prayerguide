import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/audio/sermon_recorder.dart';
import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../data/models/sermon_note.dart';
import '../../state/sermon_notes_provider.dart';
import '../../widgets/pg_header.dart';
import '../../widgets/pg_text_field.dart';
import 'sermon_share_sheet.dart';

class SermonNoteDetailScreen extends ConsumerWidget {
  const SermonNoteDetailScreen({super.key, required this.noteId});
  final String noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(sermonNotesProvider);
    final note = notesAsync.valueOrNull?.where((n) => n.id == noteId).toList();
    final found = note != null && note.isNotEmpty ? note.first : null;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: found == null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PgHeader(onBack: () => context.pop()),
                    if (notesAsync.isLoading)
                      const Expanded(
                          child: Center(child: CircularProgressIndicator())),
                  ],
                )
              : _NoteDetail(note: found),
        ),
      ),
    );
  }
}

class _NoteDetail extends ConsumerStatefulWidget {
  const _NoteDetail({required this.note});
  final SermonNote note;

  @override
  ConsumerState<_NoteDetail> createState() => _NoteDetailState();
}

class _NoteDetailState extends ConsumerState<_NoteDetail> {
  final _player = AudioPlayer();
  String? _playingRecordingId;
  bool _loadingAudio = false;
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _deleting = false;

  final _recorder = SermonRecorder();
  bool _recordingNew = false;
  bool _recorderPaused = false;
  int _elapsedSeconds = 0;
  Timer? _ticker;
  String? _recordError;

  bool _editing = false;
  bool _savingEdit = false;
  String? _editError;
  Timer? _editDebounce;
  late final _titleCtrl = TextEditingController(text: widget.note.title);
  late final _speakerCtrl =
      TextEditingController(text: widget.note.speaker ?? '');
  late final _scriptureCtrl =
      TextEditingController(text: widget.note.scriptureRef ?? '');
  late final _notesCtrl = TextEditingController(text: widget.note.notes);

  bool get _canRecord => !kIsWeb;

  @override
  void initState() {
    super.initState();
    for (final c in [_titleCtrl, _speakerCtrl, _scriptureCtrl, _notesCtrl]) {
      c.addListener(_scheduleAutoSaveEdit);
    }
    _player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _playing = s == PlayerState.playing);
    });
    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
  }

  Future<void> _togglePlay(SermonRecording recording) async {
    if (_playingRecordingId == recording.id) {
      if (_playing) {
        await _player.pause();
      } else {
        await _player.resume();
      }
      return;
    }
    setState(() {
      _playingRecordingId = recording.id;
      _loadingAudio = true;
      _position = Duration.zero;
      _duration = Duration.zero;
    });
    try {
      final url = await ref
          .read(sermonNotesRepositoryProvider)
          .signedAudioUrl(recording.audioPath);
      await _player.play(UrlSource(url));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not play recording: $e')));
      }
    } finally {
      if (mounted) setState(() => _loadingAudio = false);
    }
  }

  Future<void> _startNewRecording() async {
    final granted = await _recorder.hasPermission();
    if (!granted) {
      setState(() => _recordError = 'Microphone access is needed to record.');
      return;
    }
    await _recorder.start();
    _startTicker();
    setState(() {
      _recordingNew = true;
      _recorderPaused = false;
      _elapsedSeconds = 0;
      _recordError = null;
    });
  }

  Future<void> _togglePauseNewRecording() async {
    if (_recorderPaused) {
      await _recorder.resume();
      _startTicker();
      setState(() => _recorderPaused = false);
    } else {
      await _recorder.pause();
      _ticker?.cancel();
      setState(() => _recorderPaused = true);
    }
  }

  /// Stops and immediately attaches the take to this note — locked in, no
  /// discard/re-record; the only way to add more audio is another new take.
  Future<void> _stopAndAttach() async {
    _ticker?.cancel();
    final path = await _recorder.stop();
    final duration = _elapsedSeconds;
    setState(() {
      _recordingNew = false;
      _elapsedSeconds = 0;
    });
    if (path == null) return;
    try {
      await ref.read(sermonNotesProvider.notifier).addRecording(
            noteId: widget.note.id,
            localFilePath: path,
            durationSeconds: duration,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not save recording: $e')));
      }
    }
  }

  Future<void> _deleteRecording(SermonRecording recording) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this recording?'),
        content: const Text('This can\'t be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    if (_playingRecordingId == recording.id) {
      await _player.stop();
      setState(() => _playingRecordingId = null);
    }
    try {
      await ref
          .read(sermonNotesProvider.notifier)
          .deleteRecording(noteId: widget.note.id, recording: recording);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not delete recording: $e')));
      }
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  void _startEdit() {
    _titleCtrl.text = widget.note.title;
    _speakerCtrl.text = widget.note.speaker ?? '';
    _scriptureCtrl.text = widget.note.scriptureRef ?? '';
    _notesCtrl.text = widget.note.notes;
    setState(() {
      _editing = true;
      _editError = null;
    });
  }

  void _scheduleAutoSaveEdit() {
    if (!_editing) return;
    _editDebounce?.cancel();
    _editDebounce = Timer(const Duration(milliseconds: 800), _autoSaveEdit);
  }

  /// Persists in-progress edits without leaving edit mode — keeps typed
  /// changes from being lost if the app is killed or the user just backs
  /// out instead of tapping Save.
  Future<void> _autoSaveEdit() async {
    if (!_editing) return;
    try {
      await ref.read(sermonNotesProvider.notifier).updateNote(
            noteId: widget.note.id,
            title: _titleCtrl.text.trim(),
            speaker: _speakerCtrl.text.trim().isEmpty
                ? null
                : _speakerCtrl.text.trim(),
            scriptureRef: _scriptureCtrl.text.trim().isEmpty
                ? null
                : _scriptureCtrl.text.trim(),
            notes: _notesCtrl.text.trim(),
          );
    } catch (_) {
      // Background save — the explicit Save button (or the next debounced
      // call) surfaces/retries this; no need to interrupt typing over it.
    }
  }

  Future<void> _saveEdit() async {
    setState(() {
      _savingEdit = true;
      _editError = null;
    });
    try {
      await ref.read(sermonNotesProvider.notifier).updateNote(
            noteId: widget.note.id,
            title: _titleCtrl.text.trim(),
            speaker: _speakerCtrl.text.trim().isEmpty
                ? null
                : _speakerCtrl.text.trim(),
            scriptureRef: _scriptureCtrl.text.trim().isEmpty
                ? null
                : _scriptureCtrl.text.trim(),
            notes: _notesCtrl.text.trim(),
          );
      if (mounted) setState(() => _editing = false);
    } catch (e) {
      if (mounted) setState(() => _editError = 'Could not save: $e');
    } finally {
      if (mounted) setState(() => _savingEdit = false);
    }
  }

  /// Back arrow while editing: save whatever's been typed so far (rather
  /// than silently discarding it) and return to the read-only view.
  Future<void> _backFromEdit() async {
    _editDebounce?.cancel();
    await _autoSaveEdit();
    if (mounted) setState(() => _editing = false);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this note?'),
        content: const Text(
            'This removes the note and its recordings, if any. This can\'t be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _deleting = true);
    try {
      await ref.read(sermonNotesProvider.notifier).delete(widget.note);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _deleting = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not delete: $e')));
      }
    }
  }

  String _fmt(int seconds) =>
      '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  String _fmtDuration(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _player.dispose();
    _ticker?.cancel();
    _editDebounce?.cancel();
    if (_recordingNew) _recorder.cancel();
    _recorder.dispose();
    _titleCtrl.dispose();
    _speakerCtrl.dispose();
    _scriptureCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final note = widget.note;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PgHeader(
          onBack: _editing ? () => _backFromEdit() : () => context.pop(),
          trailing: _editing
              ? TextButton(
                  onPressed: _savingEdit ? null : _saveEdit,
                  child: Text(_savingEdit ? 'Saving…' : 'Save',
                      style: TextStyle(
                          color: c.teal,
                          fontWeight: FontWeight.w800,
                          fontSize: 14)),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                        onPressed: () => showShareSermonSheet(context,
                            sermonNoteId: note.id),
                        icon: Icon(Icons.ios_share_rounded, color: c.dim)),
                    IconButton(
                        onPressed: _startEdit,
                        icon: Icon(Icons.edit_outlined, color: c.dim)),
                    IconButton(
                      onPressed: _deleting ? null : _delete,
                      icon: _deleting
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: c.danger))
                          : Icon(Icons.delete_outline_rounded, color: c.danger),
                    ),
                  ],
                ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_editing) ...[
                  PgTextField(
                      controller: _titleCtrl,
                      hint: 'Sermon title',
                      fontWeight: FontWeight.w700),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                          child: PgTextField(
                              controller: _speakerCtrl,
                              hint: 'Speaker (optional)')),
                      const SizedBox(width: 10),
                      Expanded(
                          child: PgTextField(
                              controller: _scriptureCtrl,
                              hint: 'Scripture ref (optional)')),
                    ],
                  ),
                  if (_editError != null) ...[
                    const SizedBox(height: 8),
                    Text(_editError!,
                        style: TextStyle(color: c.danger, fontSize: 12.5)),
                  ],
                ] else ...[
                  Text(note.title,
                      style: PgText.serif(size: 25, weight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                          DateFormat('EEEE · MMMM d, yyyy')
                              .format(note.createdAt),
                          style: TextStyle(
                              fontSize: 12.5,
                              color: c.faint,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  if (note.sharedFromName != null) ...[
                    const SizedBox(height: 4),
                    Text('Shared by ${note.sharedFromName}',
                        style: TextStyle(
                            fontSize: 12.5,
                            color: c.teal,
                            fontWeight: FontWeight.w700)),
                  ],
                  if (note.speaker != null && note.speaker!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(note.speaker!,
                        style: TextStyle(
                            fontSize: 13.5,
                            color: c.dim,
                            fontWeight: FontWeight.w600)),
                  ],
                  if (note.scriptureRef != null &&
                      note.scriptureRef!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: c.tealSoft,
                          borderRadius: BorderRadius.circular(100)),
                      child: Text(note.scriptureRef!,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: c.teal)),
                    ),
                  ],
                ],
                if (note.recordings.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  for (var i = 0; i < note.recordings.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _RecordingRow(
                        index: i + 1,
                        recording: note.recordings[i],
                        isActive: _playingRecordingId == note.recordings[i].id,
                        playing: _playingRecordingId == note.recordings[i].id &&
                            _playing,
                        loading: _loadingAudio,
                        position: _position,
                        duration: _duration,
                        onTap: () => _togglePlay(note.recordings[i]),
                        onDelete: () => _deleteRecording(note.recordings[i]),
                        fmt: _fmtDuration,
                      ),
                    ),
                ],
                if (_canRecord) ...[
                  const SizedBox(height: 8),
                  if (_recordingNew)
                    _InlineRecordPanel(
                      label: _fmt(_elapsedSeconds),
                      paused: _recorderPaused,
                      onTogglePause: _togglePauseNewRecording,
                      onStop: _stopAndAttach,
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: _startNewRecording,
                      icon: Icon(Icons.mic_rounded, size: 17, color: c.teal),
                      label: Text('Record a new one',
                          style: TextStyle(
                              color: c.teal, fontWeight: FontWeight.w700)),
                    ),
                  if (_recordError != null) ...[
                    const SizedBox(height: 8),
                    Text(_recordError!,
                        style: TextStyle(color: c.danger, fontSize: 12.5)),
                  ],
                ],
                const SizedBox(height: 22),
                if (_editing)
                  PgTextField(
                    controller: _notesCtrl,
                    hint: 'Write your notes…',
                    maxLines: 14,
                    serif: true,
                    fontWeight: FontWeight.w400,
                  )
                else if (note.notes.isNotEmpty)
                  Text(note.notes,
                      style:
                          TextStyle(fontSize: 15.5, height: 1.7, color: c.text))
                else
                  Text('No written notes for this sermon.',
                      style: TextStyle(fontSize: 14, color: c.faint)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RecordingRow extends StatelessWidget {
  const _RecordingRow({
    required this.index,
    required this.recording,
    required this.isActive,
    required this.playing,
    required this.loading,
    required this.position,
    required this.duration,
    required this.onTap,
    required this.onDelete,
    required this.fmt,
  });

  final int index;
  final SermonRecording recording;
  final bool isActive;
  final bool playing;
  final bool loading;
  final Duration position;
  final Duration duration;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final String Function(Duration) fmt;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final showLoading = isActive && loading;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Material(
            color: c.teal,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: showLoading ? null : onTap,
              child: SizedBox(
                width: 42,
                height: 42,
                child: showLoading
                    ? Padding(
                        padding: const EdgeInsets.all(11),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: c.onTeal))
                    : Icon(
                        playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: c.onTeal),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Take $index',
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: c.dim)),
                Text(
                  isActive && duration > Duration.zero
                      ? '${fmt(position)} / ${fmt(duration)}'
                      : (recording.durationSeconds != null
                          ? fmt(Duration(seconds: recording.durationSeconds!))
                          : 'Recording'),
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: c.text),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onDelete,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child:
                  Icon(Icons.delete_outline_rounded, size: 18, color: c.faint),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineRecordPanel extends StatelessWidget {
  const _InlineRecordPanel({
    required this.label,
    required this.paused,
    required this.onTogglePause,
    required this.onStop,
  });

  final String label;
  final bool paused;
  final VoidCallback onTogglePause;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          if (!paused) ...[
            Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: c.danger, shape: BoxShape.circle)),
            const SizedBox(width: 8),
          ],
          Text(label,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const Spacer(),
          Material(
            color: c.surface2,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTogglePause,
              child: SizedBox(
                width: 40,
                height: 40,
                child: Icon(paused ? Icons.mic_rounded : Icons.pause_rounded,
                    color: c.text, size: 18),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: c.danger,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onStop,
              child: const SizedBox(
                  width: 40,
                  height: 40,
                  child:
                      Icon(Icons.stop_rounded, color: Colors.white, size: 18)),
            ),
          ),
        ],
      ),
    );
  }
}

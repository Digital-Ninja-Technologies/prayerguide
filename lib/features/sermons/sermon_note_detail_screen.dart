import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../data/models/sermon_note.dart';
import '../../state/sermon_notes_provider.dart';
import '../../widgets/pg_header.dart';

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
                    if (notesAsync.isLoading) const Expanded(child: Center(child: CircularProgressIndicator())),
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
  bool _loadingAudio = false;
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
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

  Future<void> _togglePlay() async {
    if (_playing) {
      await _player.pause();
      return;
    }
    if (_position > Duration.zero && _position < _duration) {
      await _player.resume();
      return;
    }
    setState(() => _loadingAudio = true);
    try {
      final url = await ref.read(sermonNotesRepositoryProvider).signedAudioUrl(widget.note.audioPath!);
      await _player.play(UrlSource(url));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not play recording: $e')));
      }
    } finally {
      if (mounted) setState(() => _loadingAudio = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this note?'),
        content: const Text('This removes the note and its recording, if any. This can\'t be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not delete: $e')));
      }
    }
  }

  String _fmt(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _player.dispose();
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
          onBack: () => context.pop(),
          trailing: IconButton(
            onPressed: _deleting ? null : _delete,
            icon: _deleting
                ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: c.danger))
                : Icon(Icons.delete_outline_rounded, color: c.danger),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(note.title, style: PgText.serif(size: 25, weight: FontWeight.w600)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(DateFormat('EEEE · MMMM d, yyyy').format(note.createdAt),
                        style: TextStyle(fontSize: 12.5, color: c.faint, fontWeight: FontWeight.w600)),
                  ],
                ),
                if (note.speaker != null && note.speaker!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(note.speaker!, style: TextStyle(fontSize: 13.5, color: c.dim, fontWeight: FontWeight.w600)),
                ],
                if (note.scriptureRef != null && note.scriptureRef!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: c.tealSoft, borderRadius: BorderRadius.circular(100)),
                    child: Text(note.scriptureRef!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: c.teal)),
                  ),
                ],
                if (note.hasAudio) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        Material(
                          color: c.teal,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _loadingAudio ? null : _togglePlay,
                            child: SizedBox(
                              width: 42,
                              height: 42,
                              child: _loadingAudio
                                  ? Padding(
                                      padding: const EdgeInsets.all(11),
                                      child: CircularProgressIndicator(strokeWidth: 2, color: c.onTeal),
                                    )
                                  : Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: c.onTeal),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _duration > Duration.zero
                                ? '${_fmt(_position)} / ${_fmt(_duration)}'
                                : (note.audioDurationSeconds != null
                                    ? _fmt(Duration(seconds: note.audioDurationSeconds!))
                                    : 'Recording'),
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.text),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                if (note.notes.isNotEmpty)
                  Text(note.notes, style: TextStyle(fontSize: 15.5, height: 1.7, color: c.text))
                else
                  Text('No written notes for this sermon.', style: TextStyle(fontSize: 14, color: c.faint)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

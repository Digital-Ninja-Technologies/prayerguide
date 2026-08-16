import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../data/models/sermon_note.dart';
import '../../state/sermon_notes_provider.dart';
import '../../state/sermon_shares_provider.dart';
import '../../widgets/pg_button.dart';
import '../../widgets/pg_card.dart';
import '../../widgets/pg_error_state.dart';

class SermonNotesScreen extends ConsumerStatefulWidget {
  const SermonNotesScreen({super.key});

  @override
  ConsumerState<SermonNotesScreen> createState() => _SermonNotesScreenState();
}

class _SermonNotesScreenState extends ConsumerState<SermonNotesScreen> {
  bool _navigating = false;

  Future<void> _createNote() async {
    if (_navigating) return;
    _navigating = true;
    await context.push('/sermons/new');
    _navigating = false;
  }

  Future<void> _openShares() async {
    if (_navigating) return;
    _navigating = true;
    await context.push('/sermons/shares');
    _navigating = false;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final notesAsync = ref.watch(sermonNotesProvider);
    final pendingCount = ref.watch(pendingSermonSharesCountProvider).valueOrNull ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Sermon Notes',
                    style: PgText.serif(size: 26, weight: FontWeight.w600)),
                Row(
                  children: [
                    _SharesInboxButton(count: pendingCount, onTap: _openShares),
                    const SizedBox(width: 10),
                    PgButton(
                      label: 'New',
                      expand: false,
                      dense: true,
                      icon: Icon(Icons.add_rounded, color: c.onTeal, size: 16),
                      onPressed: _createNote,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: notesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(
                child: PgErrorState(
                    error: e,
                    onRetry: () => ref.invalidate(sermonNotesProvider)),
              ),
              data: (notes) {
                if (notes.isEmpty) {
                  return Center(child: _EmptyState(onNew: _createNote));
                }
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(sermonNotesProvider.future),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Column(
                      children: [for (final n in notes) _NoteCard(note: n)],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SharesInboxButton extends StatelessWidget {
  const _SharesInboxButton({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 19, color: c.dim),
              if (count > 0)
                Positioned(
                  top: 2,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                        color: c.danger, borderRadius: BorderRadius.circular(100)),
                    child: Text('$count',
                        style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note});
  final SermonNote note;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PgCard(
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        onTap: () => context.push('/sermons/${note.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(note.title,
                      style: PgText.serif(size: 17, weight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                ),
                if (note.hasAudio) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.graphic_eq_rounded, size: 16, color: c.teal),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(_friendlyDate(note.createdAt),
                    style: TextStyle(
                        fontSize: 12,
                        color: c.faint,
                        fontWeight: FontWeight.w600)),
                if (note.speaker != null && note.speaker!.isNotEmpty) ...[
                  Text(' · ', style: TextStyle(fontSize: 12, color: c.faint)),
                  Expanded(
                    child: Text(note.speaker!,
                        style: TextStyle(
                            fontSize: 12,
                            color: c.faint,
                            fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ],
            ),
            if (note.scriptureRef != null && note.scriptureRef!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                    color: c.tealSoft,
                    borderRadius: BorderRadius.circular(100)),
                child: Text(note.scriptureRef!,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: c.teal)),
              ),
            ],
            if (note.notes.isNotEmpty) ...[
              const SizedBox(height: 9),
              Text(
                note.notes.length > 140
                    ? '${note.notes.substring(0, 140)}…'
                    : note.notes,
                style: TextStyle(fontSize: 13.5, height: 1.55, color: c.dim),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _friendlyDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(d.year, d.month, d.day);
    if (that == today) return 'Today';
    if (that == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('MMM d').format(d);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onNew});
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: Column(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
                color: c.tealSoft, borderRadius: BorderRadius.circular(24)),
            child: Icon(Icons.mic_none_rounded, size: 36, color: c.teal),
          ),
          const SizedBox(height: 16),
          Text('No sermon notes yet',
              style: PgText.serif(size: 21, weight: FontWeight.w600)),
          const SizedBox(height: 8),
          SizedBox(
            width: 260,
            child: Text(
              'Record the message and type along as you listen — everything saves together.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.5, height: 1.6, color: c.dim),
            ),
          ),
          const SizedBox(height: 16),
          PgButton(
              label: 'Take your first note', expand: false, onPressed: onNew),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/security/encryption_service.dart';
import '../../core/theme/pg_colors.dart';
import '../../data/models/journal_entry.dart';
import '../../state/journal_provider.dart';
import '../../state/repo_providers.dart';
import '../../widgets/pg_cloud_restore.dart';
import '../../widgets/pg_pill.dart';
import '../../widgets/pg_text_field.dart';

/// Loads an existing entry by id (from the already-fetched journal list)
/// and hands it to [JournalNewScreen] in edit mode.
class JournalEditScreen extends ConsumerWidget {
  const JournalEditScreen({super.key, required this.entryId});
  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(journalProvider).valueOrNull ?? const [];
    JournalEntry? entry;
    for (final e in entries) {
      if (e.id == entryId) {
        entry = e;
        break;
      }
    }
    if (entry == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return JournalNewScreen(entry: entry);
  }
}

class JournalNewScreen extends ConsumerStatefulWidget {
  const JournalNewScreen({super.key, this.entry});

  /// When set, this screen edits an existing entry instead of creating one.
  final JournalEntry? entry;

  @override
  ConsumerState<JournalNewScreen> createState() => _JournalNewScreenState();
}

class _JournalNewScreenState extends ConsumerState<JournalNewScreen> {
  bool get _editing => widget.entry != null;

  late String _type = widget.entry?.type ?? 'Gratitude';
  late final _title = TextEditingController(text: widget.entry?.title ?? '');
  late final _body = TextEditingController(text: widget.entry?.body ?? '');
  bool _saving = false;
  bool _deleting = false;
  String? _titleError;
  bool _needsUnlock = false;

  Future<void> _save() async {
    final title = _title.text.trim();
    final body = _body.text.trim();
    if (title.isEmpty) {
      if (body.isEmpty) {
        context.pop();
        return;
      }
      setState(() => _titleError = 'Give this entry a title.');
      return;
    }
    setState(() {
      _titleError = null;
      _saving = true;
    });
    try {
      if (_editing) {
        await ref.read(journalProvider.notifier).edit(
              id: widget.entry!.id,
              type: _type,
              title: title,
              body: body,
            );
      } else {
        await ref
            .read(journalProvider.notifier)
            .add(type: _type, title: title, body: body);
      }
      if (mounted) context.pop(true);
    } on CloudRestoreRequiredException {
      if (mounted) setState(() => _needsUnlock = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not save: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final c = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete this entry?'),
        content: const Text("This can't be undone."),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: TextStyle(color: c.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _deleting = true);
    try {
      await ref.read(journalProvider.notifier).delete(widget.entry!.id);
      if (mounted) context.pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _deleting = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not delete: $e')));
      }
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => context.pop(),
                    child: Text('Cancel',
                        style: TextStyle(
                            color: c.dim,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                  ),
                  Text(_editing ? 'Edit entry' : 'New entry',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_editing)
                        IconButton(
                          onPressed: _deleting ? null : _delete,
                          icon: _deleting
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: c.danger))
                              : Icon(Icons.delete_outline_rounded,
                                  color: c.danger, size: 20),
                        ),
                      TextButton(
                        onPressed: _saving ? null : _save,
                        child: Text('Save',
                            style: TextStyle(
                                color: c.teal,
                                fontWeight: FontWeight.w800,
                                fontSize: 14)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                child: _needsUnlock
                    ? PgCloudRestoreUnlock(
                        uid: ref.read(currentUserIdProvider)!,
                        onUnlocked: () {
                          setState(() => _needsUnlock = false);
                          _save();
                        },
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TYPE',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                  color: c.dim)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final t in const [
                                'Gratitude',
                                'Request',
                                'Testimony',
                                'Reflection'
                              ])
                                PgPill(
                                    label: t,
                                    active: _type == t,
                                    onTap: () => setState(() => _type = t)),
                            ],
                          ),
                          const SizedBox(height: 22),
                          PgTextField(
                            controller: _title,
                            hint: 'Title',
                            fontWeight: FontWeight.w600,
                            errorText: _titleError,
                          ),
                          const SizedBox(height: 12),
                          PgTextField(
                            controller: _body,
                            hint:
                                'Write freely — this stays private and encrypted.',
                            maxLines: 8,
                            serif: true,
                            fontWeight: FontWeight.w400,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Icon(Icons.lock_outline_rounded,
                                  size: 15, color: c.faint),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                    'End-to-end encrypted · only you can read this',
                                    style: TextStyle(
                                        fontSize: 12.5, color: c.faint)),
                              ),
                            ],
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

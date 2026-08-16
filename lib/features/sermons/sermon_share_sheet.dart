import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../data/models/sermon_share.dart';
import '../../state/sermon_shares_provider.dart';
import '../../widgets/pg_text_field.dart';

Future<void> showShareSermonSheet(BuildContext context, {required String sermonNoteId}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ShareSermonSheet(sermonNoteId: sermonNoteId),
  );
}

class _ShareSermonSheet extends ConsumerStatefulWidget {
  const _ShareSermonSheet({required this.sermonNoteId});
  final String sermonNoteId;

  @override
  ConsumerState<_ShareSermonSheet> createState() => _ShareSermonSheetState();
}

class _ShareSermonSheetState extends ConsumerState<_ShareSermonSheet> {
  final _queryCtrl = TextEditingController();
  Timer? _debounce;
  List<UserSearchResult> _results = [];
  bool _searching = false;
  String? _sendingId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _queryCtrl.addListener(_onChanged);
  }

  void _onChanged() {
    final value = _queryCtrl.text;
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(value));
  }

  Future<void> _search(String query) async {
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final results =
          await ref.read(sermonSharesRepositoryProvider).searchUsers(query);
      if (mounted) setState(() => _results = results);
    } catch (e) {
      if (mounted) setState(() => _error = "Couldn't search — $e");
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _send(UserSearchResult user) async {
    setState(() => _sendingId = user.id);
    try {
      await ref.read(sermonSharesRepositoryProvider).shareSermon(
            sermonNoteId: widget.sermonNoteId,
            recipientId: user.id,
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Shared with ${user.name}')),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = "Couldn't share — $e");
    } finally {
      if (mounted) setState(() => _sendingId = null);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: c.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: c.line2, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 18),
            Text('Share this sermon note',
                style: PgText.serif(size: 19, weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Search by @username, name, or exact email',
                style: TextStyle(fontSize: 13, color: c.dim)),
            const SizedBox(height: 14),
            PgTextField(
              controller: _queryCtrl,
              hint: 'Search people…',
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: c.danger, fontSize: 12.5)),
            ],
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: _searching
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _results.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            _queryCtrl.text.trim().isEmpty
                                ? 'Type @username, a name, or exact email to find someone.'
                                : 'No one found.',
                            style: TextStyle(fontSize: 13.5, color: c.faint),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: _results.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final user = _results[i];
                            return _UserResultTile(
                              user: user,
                              sending: _sendingId == user.id,
                              onTap: _sendingId == null ? () => _send(user) : null,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserResultTile extends StatelessWidget {
  const _UserResultTile({required this.user, required this.sending, required this.onTap});
  final UserSearchResult user;
  final bool sending;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration:
              BoxDecoration(border: Border.all(color: c.line), borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    color: c.tealSoft, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: TextStyle(fontWeight: FontWeight.w800, color: c.teal),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name,
                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
                    if (user.username != null)
                      Text('@${user.username}',
                          style: TextStyle(fontSize: 12, color: c.dim)),
                  ],
                ),
              ),
              if (sending)
                SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: c.teal))
              else
                Icon(Icons.send_rounded, size: 18, color: c.teal),
            ],
          ),
        ),
      ),
    );
  }
}

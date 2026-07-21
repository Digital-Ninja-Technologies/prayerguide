import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pg_colors.dart';
import '../../state/journal_provider.dart';
import '../../widgets/pg_pill.dart';
import '../../widgets/pg_text_field.dart';

class JournalNewScreen extends ConsumerStatefulWidget {
  const JournalNewScreen({super.key});

  @override
  ConsumerState<JournalNewScreen> createState() => _JournalNewScreenState();
}

class _JournalNewScreenState extends ConsumerState<JournalNewScreen> {
  String _type = 'Gratitude';
  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _saving = false;

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      context.pop();
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(journalProvider.notifier).add(
            type: _type,
            title: _title.text.trim(),
            body: _body.text.trim(),
          );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save: $e')));
        setState(() => _saving = false);
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
                    child: Text('Cancel', style: TextStyle(color: c.dim, fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                  const Text('New entry', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  TextButton(
                    onPressed: _saving ? null : _save,
                    child: Text('Save', style: TextStyle(color: c.teal, fontWeight: FontWeight.w800, fontSize: 14)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TYPE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1, color: c.dim)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final t in const ['Gratitude', 'Request', 'Testimony', 'Reflection'])
                          PgPill(label: t, active: _type == t, onTap: () => setState(() => _type = t)),
                      ],
                    ),
                    const SizedBox(height: 22),
                    PgTextField(controller: _title, hint: 'Title', fontWeight: FontWeight.w600),
                    const SizedBox(height: 12),
                    PgTextField(
                      controller: _body,
                      hint: 'Write freely — this stays private and encrypted.',
                      maxLines: 8,
                      serif: true,
                      fontWeight: FontWeight.w400,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Icon(Icons.lock_outline_rounded, size: 15, color: c.faint),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('End-to-end encrypted · only you can read this',
                              style: TextStyle(fontSize: 12.5, color: c.faint)),
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

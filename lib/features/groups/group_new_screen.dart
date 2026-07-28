import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pg_colors.dart';
import '../../state/groups_provider.dart';
import '../../widgets/pg_button.dart';
import '../../widgets/pg_header.dart';
import '../../widgets/pg_section_label.dart';
import '../../widgets/pg_text_field.dart';

class GroupNewScreen extends ConsumerStatefulWidget {
  const GroupNewScreen({super.key});

  @override
  ConsumerState<GroupNewScreen> createState() => _GroupNewScreenState();
}

class _GroupNewScreenState extends ConsumerState<GroupNewScreen> {
  final _name = TextEditingController();
  final _meetingTime = TextEditingController();
  final _joinCode = TextEditingController();
  bool _creating = false;
  bool _joining = false;
  String? _createdCode;
  String? _error;

  Future<void> _create() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _creating = true;
      _error = null;
    });
    try {
      final group = await ref.read(groupsProvider.notifier).create(
            name: name,
            meetingTime: _meetingTime.text.trim().isEmpty ? null : _meetingTime.text.trim(),
          );
      if (mounted) setState(() => _createdCode = group.inviteCode);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not create the group: $e');
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _join() async {
    final code = _joinCode.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _joining = true;
      _error = null;
    });
    try {
      await ref.read(groupsProvider.notifier).join(code);
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _meetingTime.dispose();
    _joinCode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 6, 22, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PgHeader(title: 'New group', onBack: () => context.pop()),
            if (_createdCode == null) ...[
              const PgSectionLabel('Start a group'),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PgTextField(controller: _name, hint: 'Group name', fontWeight: FontWeight.w600),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: PgTextField(controller: _meetingTime, hint: 'Meeting time (optional) — e.g. Tuesdays · 7:00 PM'),
              ),
              PgButton(label: _creating ? 'Creating…' : 'Create group', onPressed: _creating ? null : _create),
            ] else ...[
              const PgSectionLabel('Your group is ready'),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 6, 14),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(_createdCode!,
                          style: TextStyle(fontSize: 15, color: c.text, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
                    ),
                    TextButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _createdCode!));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invite code copied')));
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: c.teal,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      child: Text('Copy', style: TextStyle(color: c.onTeal, fontSize: 13, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
              Text('Share this code with anyone you want to join.', style: TextStyle(fontSize: 13, color: c.dim)),
              const SizedBox(height: 18),
              PgButton(label: 'Done', onPressed: () => context.pop()),
            ],
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: TextStyle(color: c.danger, fontSize: 12.5)),
            ],
            if (_createdCode == null) ...[
              const SizedBox(height: 26),
              const PgSectionLabel('Have a code from someone else?'),
              Row(
                children: [
                  Expanded(child: PgTextField(controller: _joinCode, hint: 'Enter their group code')),
                  const SizedBox(width: 10),
                  Material(
                    color: c.teal,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: _joining ? null : _join,
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        child: _joining
                            ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: c.onTeal))
                            : Icon(Icons.arrow_forward_rounded, color: c.onTeal),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

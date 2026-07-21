import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pg_colors.dart';
import '../../state/requests_provider.dart';
import '../../widgets/pg_pill.dart';
import '../../widgets/pg_text_field.dart';
import '../../widgets/pg_toggle.dart';

class RequestNewScreen extends ConsumerStatefulWidget {
  const RequestNewScreen({super.key});

  @override
  ConsumerState<RequestNewScreen> createState() => _RequestNewScreenState();
}

class _RequestNewScreenState extends ConsumerState<RequestNewScreen> {
  String _category = 'Healing';
  bool _reminder = true;
  bool _addToToday = false;
  final _title = TextEditingController();
  final _note = TextEditingController();
  bool _saving = false;

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      context.pop();
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(requestsProvider.notifier).add(
            category: _category,
            title: _title.text.trim(),
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
            reminder: _reminder,
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
    _note.dispose();
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
                  const Text('New request', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
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
                    Text('CATEGORY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1, color: c.dim)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final t in const ['Healing', 'Family', 'Provision', 'Guidance', 'Other'])
                          PgPill(label: t, active: _category == t, onTap: () => setState(() => _category = t)),
                      ],
                    ),
                    const SizedBox(height: 22),
                    PgTextField(controller: _title, hint: 'What are you praying for?', fontWeight: FontWeight.w600),
                    const SizedBox(height: 12),
                    PgTextField(controller: _note, hint: 'Add a note (optional)', maxLines: 4, fontWeight: FontWeight.w400),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: c.surface,
                        border: Border.all(color: c.line),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
                            child: Row(
                              children: [
                                Icon(Icons.notifications_none_rounded, size: 19, color: c.teal),
                                const SizedBox(width: 11),
                                const Expanded(child: Text('Daily reminder', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600))),
                                PgToggle(value: _reminder, onChanged: (v) => setState(() => _reminder = v)),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            child: Row(
                              children: [
                                Icon(Icons.favorite_border_rounded, size: 19, color: c.dim),
                                const SizedBox(width: 11),
                                const Expanded(child: Text("Add to today's prayer", style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600))),
                                PgToggle(value: _addToToday, onChanged: (v) => setState(() => _addToToday = v)),
                              ],
                            ),
                          ),
                        ],
                      ),
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

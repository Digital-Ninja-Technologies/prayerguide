import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pg_colors.dart';
import '../../state/challenge_provider.dart';
import '../../widgets/pg_form_error.dart';
import '../../widgets/pg_pill.dart';
import '../../widgets/pg_text_field.dart';
import '../../widgets/pg_toggle.dart';

class ChallengeNewScreen extends ConsumerStatefulWidget {
  const ChallengeNewScreen({super.key});

  @override
  ConsumerState<ChallengeNewScreen> createState() => _ChallengeNewScreenState();
}

class _ChallengeNewScreenState extends ConsumerState<ChallengeNewScreen> {
  final _name = TextEditingController();
  int _length = 30;
  String _focus = 'Growth';
  bool _reminder = true;
  bool _saving = false;
  String? _error;

  Future<void> _create() async {
    final name =
        _name.text.trim().isEmpty ? '$_focus Challenge' : _name.text.trim();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final key = 'custom-${DateTime.now().microsecondsSinceEpoch}';
      await ref
          .read(challengeRepositoryProvider)
          .start(challengeKey: key, name: name, totalDays: _length);
      ref.invalidate(challengeProvider);
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error = 'Could not create: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
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
                  const Text('New challenge',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  TextButton(
                    onPressed: _saving ? null : _create,
                    child: Text(_saving ? 'Creating…' : 'Create',
                        style: TextStyle(
                            color: c.teal,
                            fontWeight: FontWeight.w800,
                            fontSize: 14)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PgTextField(
                        controller: _name,
                        hint: 'Name your challenge',
                        fontWeight: FontWeight.w600),
                    PgFormError(_error, topSpacing: 8),
                    const SizedBox(height: 22),
                    Text('LENGTH',
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
                        for (final l in const [7, 21, 30, 40])
                          PgPill(
                              label: '$l days',
                              active: _length == l,
                              onTap: () => setState(() => _length = l)),
                        PgPill(
                            label: 'Custom',
                            active: ![7, 21, 30, 40].contains(_length),
                            onTap: () => setState(() => _length = 100)),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text('FOCUS',
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
                        for (final f in const [
                          'Growth',
                          'Fasting',
                          'Revival',
                          'Thanksgiving'
                        ])
                          PgPill(
                              label: f,
                              active: _focus == f,
                              onTap: () => setState(() => _focus = f)),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text('DAILY REMINDER',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            color: c.dim)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      margin: const EdgeInsets.only(bottom: 22),
                      decoration: BoxDecoration(
                          color: c.surface,
                          border: Border.all(color: c.line),
                          borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('8:00 AM',
                              style: TextStyle(
                                  fontSize: 14.5, fontWeight: FontWeight.w600)),
                          PgToggle(
                              value: _reminder,
                              onChanged: (v) => setState(() => _reminder = v)),
                        ],
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => context.push('/companion/invite'),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: c.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: c.line2, style: BorderStyle.solid),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                    color: c.tealSoft, shape: BoxShape.circle),
                                child: Icon(Icons.person_add_alt_1_outlined,
                                    size: 20, color: c.teal),
                              ),
                              const SizedBox(width: 13),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Invite a companion',
                                        style: TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w700)),
                                    Text(
                                        'Take it on together and cheer each other on',
                                        style: TextStyle(
                                            fontSize: 12, color: c.dim)),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, color: c.faint),
                            ],
                          ),
                        ),
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

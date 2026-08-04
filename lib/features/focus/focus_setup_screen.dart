import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pg_colors.dart';
import '../../data/static/pg_content.dart';
import '../../state/focus_provider.dart';
import '../../widgets/pg_button.dart';
import '../../widgets/pg_header.dart';
import '../../widgets/pg_section_label.dart';

class FocusSetupScreen extends ConsumerStatefulWidget {
  const FocusSetupScreen({super.key});

  @override
  ConsumerState<FocusSetupScreen> createState() => _FocusSetupScreenState();
}

class _FocusSetupScreenState extends ConsumerState<FocusSetupScreen> {
  bool _gentle = true;
  bool _starting = false;

  Future<void> _begin() async {
    setState(() => _starting = true);
    try {
      await ref.read(focusProvider.notifier).start(_gentle ? 'gentle' : 'full');
      if (mounted) context.push('/focus/active');
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
            child: PgHeader(title: 'Focus Mode', onBack: () => context.pop()),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Text(
                      'Quiet distracting apps while you pray. Calls and messages always come through.',
                      style:
                          TextStyle(fontSize: 14.5, height: 1.6, color: c.dim),
                    ),
                  ),
                  const PgSectionLabel('Mode'),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 22),
                    child: Column(
                      children: [
                        _ModeRow(
                          title: 'Gentle',
                          subtitle: 'A calm reminder overlay you can dismiss',
                          trailing: 'Free',
                          trailingColor: c.teal,
                          active: _gentle,
                          onTap: () => setState(() => _gentle = true),
                        ),
                        const SizedBox(height: 10),
                        _ModeRow(
                          title: 'Full block',
                          subtitle: 'OS-enforced app shield for the session',
                          trailing: 'Premium',
                          trailingBg: c.amberSoft,
                          trailingColor: c.amber,
                          active: !_gentle,
                          onTap: () => setState(() => _gentle = false),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const PgSectionLabel('Apps to quiet',
                          padding: EdgeInsets.zero),
                      Text('Social preset',
                          style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: c.teal)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                        color: c.surface,
                        border: Border.all(color: c.line),
                        borderRadius: BorderRadius.circular(18)),
                    child: Column(
                      children: [
                        for (var i = 0; i < focusApps.length; i++)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              border: i == focusApps.length - 1
                                  ? null
                                  : Border(bottom: BorderSide(color: c.line)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                      color: focusApps[i].$2,
                                      borderRadius: BorderRadius.circular(9)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Text(focusApps[i].$1,
                                        style: const TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w600))),
                                _MiniSwitch(on: i < 3),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  PgButton(
                    label: _starting ? 'Starting…' : 'Begin focused prayer',
                    onPressed: _starting ? null : _begin,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeRow extends StatelessWidget {
  const _ModeRow({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.trailingColor,
    this.trailingBg,
    required this.active,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String trailing;
  final Color trailingColor;
  final Color? trailingBg;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: active ? c.tealSoft : c.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: active ? c.teal : c.line),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.bg,
                  border: Border.all(
                      color: active ? c.teal : c.line2,
                      width: active ? 6 : 1.5),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    Text(subtitle,
                        style: TextStyle(fontSize: 12.5, color: c.dim)),
                  ],
                ),
              ),
              if (trailingBg != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                      color: trailingBg,
                      borderRadius: BorderRadius.circular(100)),
                  child: Text(trailing,
                      style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: trailingColor)),
                )
              else
                Text(trailing,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: trailingColor)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniSwitch extends StatelessWidget {
  const _MiniSwitch({required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 44,
      height: 26,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
          color: on ? c.teal : c.line2,
          borderRadius: BorderRadius.circular(100)),
      child: Align(
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: on ? Colors.white : c.dim)),
      ),
    );
  }
}

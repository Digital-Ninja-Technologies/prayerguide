import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pg_colors.dart';
import '../../widgets/pg_header.dart';
import '../../widgets/pg_section_label.dart';
import '../../widgets/pg_toggle.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _morning = true;
  bool _evening = true;
  bool _scripture = true;
  bool _streakProtection = false;
  bool _companionCheckins = true;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 6, 22, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PgHeader(title: 'Notifications', onBack: () => context.pop()),
            const PgSectionLabel('Prayer reminders'),
            _Group([
              _Row('Morning prayer', '6:30 AM', _morning, (v) => setState(() => _morning = v)),
              _Row('Evening prayer', '8:00 PM', _evening, (v) => setState(() => _evening = v), isLast: true),
            ]),
            const SizedBox(height: 20),
            const PgSectionLabel('Gentle nudges'),
            _Group([
              _Row('Scripture of the day', null, _scripture, (v) => setState(() => _scripture = v)),
              _Row('Streak protection', "Only if you're about to miss a day", _streakProtection,
                  (v) => setState(() => _streakProtection = v)),
              _Row('Companion check-ins', null, _companionCheckins, (v) => setState(() => _companionCheckins = v), isLast: true),
            ]),
            const SizedBox(height: 20),
            const PgSectionLabel('Quiet hours'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(18)),
              child: Row(
                children: [
                  Icon(Icons.dark_mode_outlined, size: 19, color: c.teal),
                  const SizedBox(width: 11),
                  const Expanded(child: Text('10:00 PM – 6:00 AM', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600))),
                  Text('Edit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.teal)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group(this.rows);
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(18)),
      child: Column(children: rows),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.sub, this.value, this.onChanged, {this.isLast = false});
  final String label;
  final String? sub;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(border: isLast ? null : Border(bottom: BorderSide(color: c.line))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
                if (sub != null) Text(sub!, style: TextStyle(fontSize: 11.5, color: c.faint)),
              ],
            ),
          ),
          PgToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

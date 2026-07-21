import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pg_colors.dart';
import '../../widgets/pg_header.dart';
import '../../widgets/pg_section_label.dart';

class CompanionScreen extends StatefulWidget {
  const CompanionScreen({super.key});

  @override
  State<CompanionScreen> createState() => _CompanionScreenState();
}

class _CompanionScreenState extends State<CompanionScreen> {
  String? _checkin;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 6, 22, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PgHeader(
              title: 'Companion',
              onBack: () => context.pop(),
              trailing: TextButton.icon(
                onPressed: () => context.push('/companion/invite'),
                style: TextButton.styleFrom(
                  backgroundColor: c.surface,
                  side: BorderSide(color: c.line),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                ),
                icon: Icon(Icons.add_rounded, size: 15, color: c.dim),
                label: Text('Invite', style: TextStyle(color: c.dim, fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [c.surface2, c.surface], begin: Alignment.topLeft, end: Alignment.bottomRight),
                border: Border.all(color: c.line),
                borderRadius: BorderRadius.circular(22),
              ),
              margin: const EdgeInsets.only(bottom: 18),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [c.amber, const Color(0xFF8A5A1A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    ),
                    alignment: Alignment.center,
                    child: Text('D', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.onAmber)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('David M.', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.local_fire_department_rounded, size: 15, color: c.amber),
                            const SizedBox(width: 6),
                            Text('9-day shared streak', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.amber)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(18),
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Today's check-in", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Let David know you prayed — no pressure either way.', style: TextStyle(fontSize: 12.5, color: c.dim)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      for (final v in const ['prayed', 'later', 'missed'])
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: v == 'missed' ? 0 : 9),
                            child: _CheckinBtn(
                              label: v[0].toUpperCase() + v.substring(1),
                              active: _checkin == v,
                              onTap: () => setState(() => _checkin = _checkin == v ? null : v),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const PgSectionLabel('Shared requests'),
            _SharedCard(label: 'FROM DAVID', color: c.teal, time: '2d', body: 'Wisdom for a big decision at work'),
            const SizedBox(height: 12),
            _SharedCard(label: 'YOU SHARED', color: c.amber, time: '4d', body: "Mom's recovery after surgery"),
          ],
        ),
      ),
    );
  }
}

class _CheckinBtn extends StatelessWidget {
  const _CheckinBtn({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: active ? c.teal : c.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: active ? c.teal : c.line)),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: active ? c.onTeal : c.dim)),
        ),
      ),
    );
  }
}

class _SharedCard extends StatelessWidget {
  const _SharedCard({required this.label, required this.color, required this.time, required this.body});
  final String label;
  final Color color;
  final String time;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
              Text(time, style: TextStyle(fontSize: 11.5, color: c.faint)),
            ],
          ),
          const SizedBox(height: 5),
          Text(body, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../data/static/pg_content.dart';
import '../../widgets/pg_card.dart';
import '../../widgets/pg_header.dart';
import '../../widgets/pg_icon_badge.dart';
import '../../widgets/pg_pill.dart';

class GuideLibraryScreen extends StatefulWidget {
  const GuideLibraryScreen({super.key});

  @override
  State<GuideLibraryScreen> createState() => _GuideLibraryScreenState();
}

class _GuideLibraryScreenState extends State<GuideLibraryScreen> {
  bool _morning = true;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 6, 22, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PgHeader(title: 'Prayer Guide', onBack: () => context.pop()),
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text("Choose how you'll pray today.", style: PgText.sans(size: 14.5, color: c.dim)),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Row(
                children: [
                  PgPill(label: '☀ Morning', active: _morning, onTap: () => setState(() => _morning = true)),
                  const SizedBox(width: 8),
                  PgPill(label: '☾ Evening', active: !_morning, onTap: () => setState(() => _morning = false)),
                ],
              ),
            ),
            for (final g in guideCategories)
              Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: PgCard(
                  radius: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  onTap: () => context.push('/guide'),
                  child: Row(
                    children: [
                      PgIconBadge(
                        icon: Icons.spa_outlined,
                        color: g.teal ? c.teal : c.amber,
                        background: g.teal ? c.tealSoft : c.amberSoft,
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(g.name, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
                            Text(g.desc, style: TextStyle(fontSize: 12.5, color: c.dim)),
                          ],
                        ),
                      ),
                      Text(g.duration, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.faint)),
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

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../data/static/pg_content.dart';
import '../../widgets/pg_card.dart';
import '../../widgets/pg_icon_badge.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 6, 22, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Groups', style: PgText.serif(size: 26, weight: FontWeight.w600)),
                  TextButton(
                    onPressed: () => context.push('/together'),
                    style: TextButton.styleFrom(
                      backgroundColor: c.surface,
                      side: BorderSide(color: c.line),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                    ),
                    child: Text('Pray together', style: TextStyle(color: c.dim, fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            for (final g in groupsCatalog)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PgCard(
                  radius: 18,
                  padding: const EdgeInsets.all(16),
                  onTap: () => context.push(g.live ? '/room' : '/groups'),
                  child: Row(
                    children: [
                      PgIconBadge(icon: Icons.diversity_1_outlined, color: c.teal, background: c.tealSoft),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(g.name, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
                            Text(g.members, style: TextStyle(fontSize: 12.5, color: c.dim)),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: g.live ? c.teal : c.faint),
                          ),
                          const SizedBox(width: 6),
                          Text(g.meta, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: g.live ? c.teal : c.faint)),
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

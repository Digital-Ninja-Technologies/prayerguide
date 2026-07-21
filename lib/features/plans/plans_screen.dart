import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pg_colors.dart';
import '../../data/static/pg_content.dart';
import '../../widgets/pg_card.dart';
import '../../widgets/pg_header.dart';
import '../../widgets/pg_icon_badge.dart';

class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 6, 22, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PgHeader(title: 'Reading Plans', onBack: () => context.pop()),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text('Read through Scripture at a pace that fits your life.', style: TextStyle(fontSize: 14.5, color: c.dim)),
            ),
            for (final p in readingPlanCatalog.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: PgCard(
                  radius: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  onTap: () => context.push('/plans/${p.key}'),
                  child: Row(
                    children: [
                      PgIconBadge(icon: Icons.menu_book_outlined, color: c.teal, background: c.tealSoft, size: 44, radius: 13),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
                            Text(p.sub, style: TextStyle(fontSize: 12.5, color: c.dim)),
                          ],
                        ),
                      ),
                      Text(
                        p.key == 'oneYear' ? '18%' : 'Start',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.teal),
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

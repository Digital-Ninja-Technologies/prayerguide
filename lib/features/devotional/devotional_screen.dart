import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../widgets/pg_button.dart';
import '../../widgets/pg_header.dart';

class DevotionalScreen extends StatelessWidget {
  const DevotionalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 6, 22, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PgHeader(eyebrow: 'DEVOTIONAL · JULY 21', onBack: () => context.pop()),
            Text('Anchored', style: PgText.serif(size: 30, weight: FontWeight.w600)),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text('Hebrews 6:19', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: c.amber)),
            ),
            Container(
              padding: const EdgeInsets.only(left: 16),
              margin: const EdgeInsets.only(bottom: 22),
              decoration: BoxDecoration(border: Border(left: BorderSide(color: c.amber, width: 2))),
              child: Text(
                '"Which hope we have as an anchor of the soul, both sure and stedfast…"',
                style: PgText.serif(size: 17, style: FontStyle.italic, height: 1.55),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "An anchor doesn't stop the storm — it holds you steady inside it. The writer of Hebrews calls our hope in God exactly that: sure and steadfast.",
                    style: TextStyle(fontSize: 15.5, height: 1.75, color: c.text),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "Whatever waves are moving your circumstances today, they don't move the One your hope is fastened to. Let that settle your heart before you pray.",
                    style: TextStyle(fontSize: 15.5, height: 1.75, color: c.text),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(18),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: c.surface2, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(18)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('REFLECT', style: PgText.sans(size: 11, weight: FontWeight.w800, color: c.dim, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Text('What storm are you asking God to calm, and can you trust the anchor to hold?',
                      style: PgText.serif(size: 17, height: 1.5)),
                ],
              ),
            ),
            PgButton(label: 'Pray & mark complete', onPressed: () => context.push('/timer')),
          ],
        ),
      ),
    );
  }
}

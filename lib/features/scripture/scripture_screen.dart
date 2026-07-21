import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../widgets/pg_button.dart';
import '../../widgets/pg_header.dart';

class ScriptureScreen extends StatelessWidget {
  const ScriptureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(26, 6, 26, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PgHeader(eyebrow: 'JULY 21', onBack: () => context.pop()),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  Text('SCRIPTURE OF THE DAY',
                      textAlign: TextAlign.center,
                      style: PgText.serif(size: 11, letterSpacing: 3, color: c.teal)),
                  const SizedBox(height: 20),
                  Text(
                    '"Be still, and know that I am God: I will be exalted among the heathen, I will be exalted in the earth."',
                    textAlign: TextAlign.center,
                    style: PgText.serif(size: 27, weight: FontWeight.w500, height: 1.5),
                  ),
                  const SizedBox(height: 18),
                  Text('Psalm 46:10 · KJV', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.amber)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _Block(
              label: 'EXPLANATION',
              labelColor: c.teal,
              body:
                  "In the middle of chaos, God's invitation is not to strive harder but to grow still. Stillness is where we remember who holds the world — and that it isn't us.",
            ),
            const SizedBox(height: 14),
            _Block(
              label: 'PRAYER FOCUS',
              labelColor: c.amber,
              body: 'Ask God to quiet an anxious part of your heart today, and to help you rest in his authority.',
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: c.surface2,
                border: Border.all(color: c.line),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('REFLECTION QUESTION',
                      style: PgText.sans(size: 12, weight: FontWeight.w700, color: c.dim, letterSpacing: 1)),
                  const SizedBox(height: 10),
                  Text('What are you trying to control that you could hand to God today?',
                      style: PgText.serif(size: 18, height: 1.5)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            PgButton(label: 'Pray on this', onPressed: () => context.push('/timer')),
          ],
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.label, required this.labelColor, required this.body});

  final String label;
  final Color labelColor;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: PgText.sans(size: 12, weight: FontWeight.w700, color: labelColor, letterSpacing: 1)),
          const SizedBox(height: 10),
          Text(body, style: TextStyle(fontSize: 15, height: 1.65, color: c.text)),
        ],
      ),
    );
  }
}

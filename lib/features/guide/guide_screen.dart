import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../widgets/pg_button.dart';
import '../../widgets/pg_header.dart';
import '../../widgets/pg_pill.dart';

const _prayerPoints = [
  "Thank God for his faithfulness through the night.",
  'Give thanks for provision and daily bread.',
  'Praise him for his timing, even in unanswered prayers.',
  'Offer gratitude for the people he has placed in your life.',
];

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 6, 24, 130),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PgHeader(eyebrow: 'DAILY PRAYER GUIDE', onBack: () => context.pop()),
                Row(
                  children: [
                    PgPill(label: '☀ Morning', active: true),
                    const SizedBox(width: 8),
                    PgPill(
                      label: '8 min',
                      active: true,
                      activeColor: c.amberSoft,
                      activeFg: c.amber,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text('Thanksgiving', style: PgText.serif(size: 32, weight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                  "Begin the day by naming what God has done. Let gratitude quiet the noise before you ask for anything.",
                  style: PgText.sans(size: 15, height: 1.6, color: c.dim),
                ),
                const SizedBox(height: 26),
                Container(
                  padding: const EdgeInsets.only(left: 18),
                  decoration: BoxDecoration(border: Border(left: BorderSide(color: c.amber, width: 2))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '"Be careful for nothing; but in every thing by prayer and supplication with thanksgiving let your requests be made known unto God."',
                        style: PgText.serif(size: 18, style: FontStyle.italic, height: 1.55),
                      ),
                      const SizedBox(height: 10),
                      Text('Philippians 4:6',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.amber)),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Text('PRAYER POINTS',
                    style: PgText.sans(size: 12, weight: FontWeight.w700, color: c.teal, letterSpacing: 1)),
                const SizedBox(height: 14),
                for (var i = 0; i < _prayerPoints.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: c.tealSoft, shape: BoxShape.circle),
                          child: Text('${i + 1}',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: c.teal)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(_prayerPoints[i], style: const TextStyle(fontSize: 15, height: 1.5)),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: c.surface,
                    border: Border.all(color: c.line),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('REFLECTION',
                          style: PgText.sans(size: 12, weight: FontWeight.w700, color: c.dim, letterSpacing: 1)),
                      const SizedBox(height: 8),
                      Text("Where have you seen God's hand at work this week?",
                          style: PgText.serif(size: 17, height: 1.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [c.bg, c.bg.withOpacity(0)],
                  stops: const [0.62, 1],
                ),
              ),
              child: PgButton(
                label: 'Begin — 8 min',
                icon: Icon(Icons.play_arrow_rounded, color: c.onTeal, size: 20),
                onPressed: () => context.push('/timer'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

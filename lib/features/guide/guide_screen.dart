import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../data/static/pg_content.dart';
import '../../widgets/pg_button.dart';
import '../../widgets/pg_header.dart';
import '../../widgets/pg_pill.dart';

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key, this.category});
  final String? category;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final meta = guideCategories.firstWhere(
      (g) => g.name == category,
      orElse: () => guideCategories.first,
    );
    final content = guideContentByCategory[meta.name] ??
        guideContentByCategory['Thanksgiving']!;

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
            child: PgHeader(
                eyebrow: 'DAILY PRAYER GUIDE', onBack: () => context.pop()),
          ),
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 130),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const PgPill(label: '☀ Morning', active: true),
                          const SizedBox(width: 8),
                          PgPill(
                            label: meta.duration,
                            active: true,
                            activeColor: c.amberSoft,
                            activeFg: c.amber,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(meta.name,
                          style:
                              PgText.serif(size: 32, weight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(
                        content.intro,
                        style: PgText.sans(size: 15, height: 1.6, color: c.dim),
                      ),
                      const SizedBox(height: 26),
                      Container(
                        padding: const EdgeInsets.only(left: 18),
                        decoration: BoxDecoration(
                            border: Border(
                                left: BorderSide(color: c.amber, width: 2))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '"${content.verse}"',
                              style: PgText.serif(
                                  size: 18,
                                  style: FontStyle.italic,
                                  height: 1.55),
                            ),
                            const SizedBox(height: 10),
                            Text(content.reference,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: c.amber)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text('PRAYER POINTS',
                          style: PgText.sans(
                              size: 12,
                              weight: FontWeight.w700,
                              color: c.teal,
                              letterSpacing: 1)),
                      const SizedBox(height: 14),
                      for (var i = 0; i < content.prayerPoints.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    color: c.tealSoft, shape: BoxShape.circle),
                                child: Text('${i + 1}',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: c.teal)),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(content.prayerPoints[i],
                                    style: const TextStyle(
                                        fontSize: 15, height: 1.5)),
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
                                style: PgText.sans(
                                    size: 12,
                                    weight: FontWeight.w700,
                                    color: c.dim,
                                    letterSpacing: 1)),
                            const SizedBox(height: 8),
                            Text(content.reflection,
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
                        colors: [c.bg, c.bg.withValues(alpha: 0)],
                        stops: const [0.62, 1],
                      ),
                    ),
                    child: PgButton(
                      label: 'Begin — ${meta.duration}',
                      icon: Icon(Icons.play_arrow_rounded,
                          color: c.onTeal, size: 20),
                      onPressed: () => context.push(
                        '/timer?category=${Uri.encodeComponent(meta.name)}&minutes=${meta.durationMinutes}',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

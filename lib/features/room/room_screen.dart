import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../widgets/pg_back_button.dart';

class RoomScreen extends StatelessWidget {
  const RoomScreen({super.key});

  static const _members = [
    ('Grace', true, true),
    ('David', false, false),
    ('Maria', false, false),
    ('John', false, false),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(center: const Alignment(0, -0.6), radius: 1, colors: [c.tealSoft, Colors.transparent]),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 6, 22, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      PgBackButton(onTap: () => context.pop()),
                      Row(
                        children: [
                          Container(width: 8, height: 8, decoration: BoxDecoration(color: c.teal, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text('LIVE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: c.teal)),
                        ],
                      ),
                      const SizedBox(width: 38),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tuesday Small Group', style: PgText.serif(size: 22, weight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('9 in the room · hosted by Grace', style: TextStyle(fontSize: 13, color: c.dim)),
                      const SizedBox(height: 22),
                      GridView.count(
                        crossAxisCount: 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.75,
                        children: [
                          for (final m in _members) _MemberAvatar(name: m.$1, host: m.$2, speaking: m.$3),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 34),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: c.line),
                            padding: const EdgeInsets.all(15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: Icon(Icons.back_hand_outlined, size: 18, color: c.text),
                          label: Text('Raise hand', style: TextStyle(color: c.text, fontSize: 14.5, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => context.pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: c.danger,
                            padding: const EdgeInsets.all(15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Leave', style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
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

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.name, required this.host, required this.speaking});
  final String name;
  final bool host;
  final bool speaking;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: host ? null : c.surface2,
                gradient: host ? LinearGradient(colors: [c.teal, c.tealDeep], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
                border: speaking ? Border.all(color: c.teal, width: 2) : null,
              ),
              alignment: Alignment.center,
              child: Text(name[0], style: TextStyle(fontWeight: FontWeight.w800, color: host ? c.onTeal : c.dim)),
            ),
            if (speaking)
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(color: c.teal, shape: BoxShape.circle, border: Border.all(color: c.bg, width: 2)),
                  child: Icon(Icons.mic_rounded, size: 10, color: c.onTeal),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: host ? null : c.dim)),
      ],
    );
  }
}

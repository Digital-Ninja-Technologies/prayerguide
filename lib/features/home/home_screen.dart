import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../data/devotional/devotional_library.dart';
import '../../data/models/challenge_progress.dart';
import '../../data/scripture/scripture_of_day_library.dart';
import '../../data/static/pg_content.dart';
import '../../state/bible_library_provider.dart';
import '../../state/challenge_provider.dart';
import '../../state/companion_provider.dart';
import '../../state/notifications_provider.dart';
import '../../state/profile_provider.dart';
import '../../widgets/pg_card.dart';
import '../../widgets/pg_section_label.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    // Watching this here (rather than only on the Notifications screen)
    // ensures reminders get (re)scheduled once per app session even if the
    // user never opens Settings.
    ref.watch(notificationsProvider);
    final profileAsync = ref.watch(profileProvider);
    final streak = profileAsync.valueOrNull?.streakCount ?? 0;
    final name = profileAsync.valueOrNull?.name;
    final greetingName =
        (name == null || name.isEmpty) ? 'friend' : name.split(' ').first;
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE · MMMM d').format(now);
    final timeOfDay = now.hour < 12 ? 'Morning' : (now.hour < 18 ? 'Afternoon' : 'Evening');
    final scriptureEntry = scriptureOfDayForDate(now);
    final devotionalEntry = devotionalForDate(now);
    final libraryAsync = ref.watch(bibleLibraryProvider);
    final companionAsync = ref.watch(companionProvider);
    final companionName = companionAsync.valueOrNull?.companion?.otherName;
    final challengesAsync = ref.watch(challengeProvider);
    final activeChallenge = challengesAsync.valueOrNull
        ?.where((p) => p.active && p.currentDay < p.totalDays)
        .fold<ChallengeProgress?>(null, (best, p) => best == null || p.startedAt.isAfter(best.startedAt) ? p : best);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dateStr.toUpperCase(),
                        style: PgText.sans(
                            size: 12.5,
                            weight: FontWeight.w600,
                            color: c.dim,
                            letterSpacing: .6)),
                    const SizedBox(height: 5),
                    Text('Greetings,\n$greetingName',
                        style: PgText.serif(
                            size: 27, weight: FontWeight.w600, height: 1.15)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => context.go('/streak'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                  decoration: BoxDecoration(
                    color: c.amberSoft,
                    border: Border.all(color: c.line),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.local_fire_department_rounded,
                          size: 17, color: c.amber),
                      const SizedBox(width: 6),
                      Text('$streak',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: c.amber)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          PgCard(
            radius: 24,
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [c.surface2, c.surface],
            ),
            onTap: () => context.push('/scripture'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('SCRIPTURE OF THE DAY',
                        style: PgText.sans(
                            size: 11,
                            weight: FontWeight.w700,
                            color: c.teal,
                            letterSpacing: 1)),
                    Icon(Icons.chevron_right_rounded, color: c.dim),
                  ],
                ),
                const SizedBox(height: 14),
                libraryAsync.when(
                  loading: () => const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2)),
                  error: (e, st) => Text('Could not load scripture text.', style: TextStyle(color: c.danger)),
                  data: (library) {
                    final verses = library.versesFor(scriptureEntry.book, scriptureEntry.chapter);
                    final text = verses.isEmpty
                        ? ''
                        : verses.sublist(scriptureEntry.verseStart - 1, scriptureEntry.verseEnd).join(' ');
                    return Text('"$text"',
                        style: PgText.serif(size: 22, weight: FontWeight.w500, height: 1.4));
                  },
                ),
                const SizedBox(height: 12),
                Text(scriptureEntry.reference,
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: c.amber)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          PgCard(
            radius: 22,
            color: c.teal,
            borderColor: c.teal,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            onTap: () => context.push('/guide'),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: c.onTeal.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child:
                      Icon(Icons.play_arrow_rounded, size: 27, color: c.onTeal),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Start today's prayer",
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: c.onTeal)),
                      const SizedBox(height: 3),
                      Text('$timeOfDay · ${guideCategories.first.name} · ${guideCategories.first.duration}',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: c.onTeal.withValues(alpha: .72))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: PgCard(
                  radius: 20,
                  padding: const EdgeInsets.all(17),
                  onTap: () => context.go('/journal'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.edit_note_rounded, color: c.teal, size: 24),
                      const SizedBox(height: 12),
                      const Text('Journal',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('Private entries',
                          style: TextStyle(fontSize: 12.5, color: c.dim)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PgCard(
                  radius: 20,
                  padding: const EdgeInsets.all(17),
                  onTap: () => context.push('/requests'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.favorite_border_rounded,
                          color: c.amber, size: 24),
                      const SizedBox(height: 12),
                      const Text('Requests',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('Track & pray',
                          style: TextStyle(fontSize: 12.5, color: c.dim)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const PgSectionLabel('More ways to pray',
              padding: EdgeInsets.only(bottom: 12)),
          SizedBox(
            height: 108,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _MiniTile(
                  icon: Icons.menu_book_outlined,
                  color: c.amber,
                  title: 'Devotional',
                  subtitle: 'Today · ${devotionalEntry.title}',
                  onTap: () => context.push('/devotional'),
                ),
                _MiniTile(
                  icon: Icons.emoji_events_outlined,
                  color: c.teal,
                  title: 'Challenges',
                  subtitle: activeChallenge == null
                      ? 'Start a challenge'
                      : '${activeChallenge.totalDays} Days · Day ${activeChallenge.currentDay + 1}',
                  onTap: () => context.push('/challenges'),
                ),
                _MiniTile(
                  icon: Icons.diversity_1_outlined,
                  color: c.teal,
                  title: 'Companion',
                  subtitle: companionName == null ? 'Invite a companion' : 'Pray with $companionName',
                  onTap: () => context.push('/companion'),
                  last: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTile extends StatelessWidget {
  const _MiniTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.last = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.only(right: last ? 0 : 10),
      child: PgCard(
        radius: 18,
        padding: const EdgeInsets.all(15),
        onTap: onTap,
        child: SizedBox(
          width: 130,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 10),
              Text(title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(fontSize: 11.5, color: c.dim),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

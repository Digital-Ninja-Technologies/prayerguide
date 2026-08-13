import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../data/devotional/devotional_library.dart';
import '../../data/models/challenge_progress.dart';
import '../../data/scripture/scripture_of_day_library.dart';
import '../../data/static/pg_content.dart';
import '../../state/bible_library_provider.dart';
import '../../state/challenge_provider.dart';
import '../../state/companion_provider.dart';
import '../../state/groups_provider.dart';
import '../../state/notifications_provider.dart';
import '../../state/profile_provider.dart';
import '../../widgets/pg_button.dart';
import '../../widgets/pg_card.dart';
import '../../widgets/pg_section_label.dart';

const _kStreakPopupDateKey = 'streak_popup_last_shown_date';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _appOpenChecked = false;
  bool _streakPopupChecked = false;

  Future<void> _maybeShowStreakPopup(
      int prayerStreak, int appOpenStreak) async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (prefs.getString(_kStreakPopupDateKey) == todayKey) return;
    await prefs.setString(_kStreakPopupDateKey, todayKey);
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) => _StreakPopup(
          prayerStreak: prayerStreak, appOpenStreak: appOpenStreak),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Watching this here (rather than only on the Notifications screen)
    // ensures reminders get (re)scheduled once per app session even if the
    // user never opens Settings.
    ref.watch(notificationsProvider);
    final profileAsync = ref.watch(profileProvider);
    final streak = profileAsync.valueOrNull?.streakCount ?? 0;
    final appOpenStreak = profileAsync.valueOrNull?.appOpenStreakCount ?? 0;
    final name = profileAsync.valueOrNull?.name;

    if (!_appOpenChecked && profileAsync.hasValue) {
      _appOpenChecked = true;
      ref.read(profileProvider.notifier).recordAppOpen();
    }
    if (!_streakPopupChecked && profileAsync.hasValue) {
      _streakPopupChecked = true;
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => _maybeShowStreakPopup(streak, appOpenStreak));
    }
    final greetingName =
        (name == null || name.isEmpty) ? 'friend' : name.split(' ').first;
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE · MMMM d').format(now);
    final timeOfDay =
        now.hour < 12 ? 'Morning' : (now.hour < 18 ? 'Afternoon' : 'Evening');
    final scriptureEntry = scriptureOfDayForDate(now);
    final devotionalEntry = devotionalForDate(now);
    final libraryAsync = ref.watch(bibleLibraryProvider);
    final companionsAsync = ref.watch(companionsProvider);
    final companions = companionsAsync.valueOrNull ?? const [];
    final groupsAsync = ref.watch(groupsProvider);
    final groups = groupsAsync.valueOrNull ?? const [];
    final challengesAsync = ref.watch(challengeProvider);
    final activeChallenge = challengesAsync.valueOrNull
        ?.where((p) => p.active && p.currentDay < p.totalDays)
        .fold<ChallengeProgress?>(
            null,
            (best, p) =>
                best == null || p.startedAt.isAfter(best.startedAt) ? p : best);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
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
                        Text('Good $timeOfDay,\n$greetingName',
                            style: PgText.serif(
                                size: 27,
                                weight: FontWeight.w600,
                                height: 1.15)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/streak'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _HeaderStreakChip(
                          icon: Icons.local_fire_department_rounded,
                          color: c.amber,
                          background: c.amberSoft,
                          value: streak,
                        ),
                        const SizedBox(height: 6),
                        _HeaderStreakChip(
                          icon: Icons.calendar_month_rounded,
                          color: c.teal,
                          background: c.tealSoft,
                          value: appOpenStreak,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => Future.wait([
              ref.refresh(profileProvider.future),
              ref.refresh(companionsProvider.future),
              ref.refresh(groupsProvider.future),
              ref.refresh(challengeProvider.future),
            ]),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 34),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                          loading: () => const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                          error: (e, st) => Text(
                              'Could not load scripture text.',
                              style: TextStyle(color: c.danger)),
                          data: (library) {
                            final verses = library.versesFor(
                                scriptureEntry.book, scriptureEntry.chapter);
                            final text = verses.isEmpty
                                ? ''
                                : verses
                                    .sublist(scriptureEntry.verseStart - 1,
                                        scriptureEntry.verseEnd)
                                    .join(' ');
                            return Text('"$text"',
                                style: PgText.serif(
                                    size: 22,
                                    weight: FontWeight.w500,
                                    height: 1.4));
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 20),
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
                          child: Icon(Icons.play_arrow_rounded,
                              size: 27, color: c.onTeal),
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
                              Text(
                                  '$timeOfDay · ${guideCategories.first.name} · ${guideCategories.first.duration}',
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
                              Icon(Icons.edit_note_rounded,
                                  color: c.teal, size: 24),
                              const SizedBox(height: 12),
                              const Text('Journal',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text('Private entries',
                                  style:
                                      TextStyle(fontSize: 12.5, color: c.dim)),
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
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text('Track & pray',
                                  style:
                                      TextStyle(fontSize: 12.5, color: c.dim)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const PgSectionLabel('More ways to pray',
                      padding: EdgeInsets.only(bottom: 12)),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.55,
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
                        subtitle: companions.isEmpty
                            ? 'Invite a companion'
                            : companions.length == 1
                                ? 'Pray with ${companions.first.otherName}'
                                : '${companions.length} companions',
                        onTap: () => context.push('/companion'),
                      ),
                      _MiniTile(
                        icon: Icons.groups_outlined,
                        color: c.amber,
                        title: 'Groups',
                        subtitle: groups.isEmpty
                            ? 'Join a group'
                            : groups.length == 1
                                ? groups.first.name
                                : '${groups.length} groups',
                        onTap: () => context.push('/groups'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderStreakChip extends StatelessWidget {
  const _HeaderStreakChip({
    required this.icon,
    required this.color,
    required this.background,
    required this.value,
  });
  final IconData icon;
  final Color color;
  final Color background;
  final int value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 6),
          Text('$value',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

/// Shown once per calendar day when the user opens Home — surfaces both
/// streaks: the app-open streak (today's visit is what earns this one) and
/// the prayer streak (only earned by actually praying).
class _StreakPopup extends StatelessWidget {
  const _StreakPopup({required this.prayerStreak, required this.appOpenStreak});
  final int prayerStreak;
  final int appOpenStreak;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final message = prayerStreak <= 0
        ? "Good to see you again. Pray for at least 3 minutes today to start your prayer streak too."
        : "You've shown up $appOpenStreak day${appOpenStreak == 1 ? '' : 's'} in a row, and prayed $prayerStreak of them. No pressure, only presence.";

    return Dialog(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StreakStat(
                  icon: Icons.calendar_month_rounded,
                  color: c.teal,
                  background: c.tealSoft,
                  value: appOpenStreak,
                  label: 'day streak',
                ),
                const SizedBox(width: 18),
                _StreakStat(
                  icon: Icons.local_fire_department_rounded,
                  color: c.amber,
                  background: c.amberSoft,
                  value: prayerStreak,
                  label: 'prayer streak',
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.6, color: c.dim),
            ),
            const SizedBox(height: 22),
            PgButton(
              label: 'Continue',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakStat extends StatelessWidget {
  const _StreakStat({
    required this.icon,
    required this.color,
    required this.background,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final Color color;
  final Color background;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
              border: Border.all(color: c.line)),
          child: Icon(icon, size: 28, color: color),
        ),
        const SizedBox(height: 10),
        Text('$value',
            style: const TextStyle(
                fontSize: 30, fontWeight: FontWeight.w800, height: 1)),
        const SizedBox(height: 2),
        Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 11.5, fontWeight: FontWeight.w700, color: c.dim)),
      ],
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
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PgCard(
      radius: 18,
      padding: const EdgeInsets.all(15),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 10),
          Text(title,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(subtitle,
              style: TextStyle(fontSize: 11.5, color: c.dim),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

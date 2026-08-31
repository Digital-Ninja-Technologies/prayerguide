import 'package:flutter/material.dart';

class GuideCategory {
  const GuideCategory(this.name, this.desc, this.duration, this.teal);
  final String name;
  final String desc;
  final String duration;
  final bool teal; // true = teal accent, false = amber accent

  int get durationMinutes => int.parse(duration.split(' ').first);
}

const guideCategories = [
  GuideCategory('Thanksgiving', 'Begin the day in gratitude', '8 min', false),
  GuideCategory('Worship', 'Adore who God is', '10 min', true),
  GuideCategory('Repentance', 'Return with a soft heart', '7 min', true),
  GuideCategory('Family', 'Lift up those you love', '9 min', false),
  GuideCategory('Healing', 'Pray for restoration', '10 min', true),
  GuideCategory('Spiritual Growth', 'Grow deeper roots', '12 min', false),
];

class GuideContent {
  const GuideContent({
    required this.category,
    required this.intro,
    required this.verse,
    required this.reference,
    required this.prayerPoints,
    required this.reflection,
  });

  final String category;
  final String intro;
  final String verse;
  final String reference;
  final List<String> prayerPoints;
  final String reflection;
}

const _guideContentList = [
  GuideContent(
    category: 'Thanksgiving',
    intro: "Begin the day by naming what God has done. Let gratitude quiet the noise before you ask for anything.",
    verse:
        "Be careful for nothing; but in every thing by prayer and supplication with thanksgiving let your requests be made known unto God.",
    reference: 'Philippians 4:6',
    prayerPoints: [
      'Thank God for his faithfulness through the night.',
      'Give thanks for provision and daily bread.',
      'Praise him for his timing, even in unanswered prayers.',
      'Offer gratitude for the people he has placed in your life.',
    ],
    reflection: "Where have you seen God's hand at work this week?",
  ),
  GuideContent(
    category: 'Thanksgiving',
    intro: "Some days gratitude is easy to find; other days it takes searching. Either way, thanksgiving opens the door to everything else.",
    verse: 'O give thanks unto the LORD; for he is good: for his mercy endureth for ever.',
    reference: 'Psalm 107:1',
    prayerPoints: [
      'Thank God for something specific from the last 24 hours.',
      'Give thanks for a person who showed you kindness recently.',
      "Praise him for strength he gave you when you didn't feel strong.",
      'Thank him in advance for what he is already working out.',
    ],
    reflection: "What's one thing you almost forgot to thank God for?",
  ),
  GuideContent(
    category: 'Worship',
    intro: 'Set your eyes on who God is before anything else. Worship makes room for everything that follows.',
    verse: 'Bless the LORD, O my soul: and all that is within me, bless his holy name.',
    reference: 'Psalm 103:1',
    prayerPoints: [
      "Declare God's greatness — his power, holiness, and majesty.",
      'Thank him for his unchanging character.',
      'Praise him simply for who he is, apart from what he gives.',
      'Sit quietly in his presence without asking for anything.',
    ],
    reflection: 'What is one attribute of God you want to praise him for today?',
  ),
  GuideContent(
    category: 'Worship',
    intro: "Worship isn't about finding the right words — it's about turning your attention toward him and staying there a moment longer than feels natural.",
    verse: 'O come, let us worship and bow down: let us kneel before the LORD our maker.',
    reference: 'Psalm 95:6',
    prayerPoints: [
      "Worship God for his faithfulness, even when you couldn't see it.",
      'Thank him for being the same yesterday, today, and forever.',
      'Praise him for his patience with you.',
      "Let go of the need to perform — just be still before him.",
    ],
    reflection: "When did you most recently sense God's presence — and why?",
  ),
  GuideContent(
    category: 'Repentance',
    intro: 'Come honestly. Let his kindness — not shame — lead you back to a soft, teachable heart.',
    verse: 'If we confess our sins, he is faithful and just to forgive us our sins, and to cleanse us from all unrighteousness.',
    reference: '1 John 1:9',
    prayerPoints: [
      'Ask God to search your heart and reveal anything unconfessed.',
      'Name specific ways you fell short this week, honestly and without excuse.',
      "Receive his forgiveness — he isn't waiting to condemn you.",
      'Ask for grace to walk differently going forward.',
    ],
    reflection: 'Is there anything you have been avoiding bringing to God?',
  ),
  GuideContent(
    category: 'Repentance',
    intro: "God isn't asking you to clean yourself up before you come — he's asking you to come as you are and let him do the cleaning.",
    verse: 'Create in me a clean heart, O God; and renew a right spirit within me.',
    reference: 'Psalm 51:10',
    prayerPoints: [
      'Ask God to show you where pride has crept in.',
      'Confess a specific pattern, not just a general feeling of guilt.',
      'Thank him that his mercy is new, not just for today but every day.',
      "Ask for the courage to make one thing right that you've been avoiding.",
    ],
    reflection: "Is there a relationship you need to make right, not just with God, but with someone else?",
  ),
  GuideContent(
    category: 'Family',
    intro: 'Carry the people closest to you before the Father who loves them even more than you do.',
    verse: 'As for me and my house, we will serve the LORD.',
    reference: 'Joshua 24:15',
    prayerPoints: [
      'Pray by name for each person in your household.',
      'Ask for patience and gentleness in a specific relationship.',
      'Pray protection and wisdom over your family this week.',
      'Thank God for one thing about your family right now.',
    ],
    reflection: 'Who in your family needs your prayer most today?',
  ),
  GuideContent(
    category: 'Family',
    intro: 'Your family may be the hardest place to be patient and the most important place to be faithful. Bring them honestly before God today.',
    verse: 'Train up a child in the way he should go: and when he is old, he will not depart from it.',
    reference: 'Proverbs 22:6',
    prayerPoints: [
      'Pray for unity in your household, even amid disagreement.',
      'Ask God to soften a strained relationship.',
      'Pray for the children in your life — yours, or ones you love.',
      'Thank God for the family he has given you, imperfect as it is.',
    ],
    reflection: "Is there a family member you've been meaning to call or check in on?",
  ),
  GuideContent(
    category: 'Healing',
    intro: 'Bring what is broken — body, heart, or relationship — to the God who restores.',
    verse: 'He healeth the broken in heart, and bindeth up their wounds.',
    reference: 'Psalm 147:3',
    prayerPoints: [
      'Name a physical, emotional, or relational wound and bring it to God.',
      'Pray for someone you know who is walking through pain right now.',
      'Ask God for patience while you wait on healing that hasn\'t come yet.',
      'Thank him for the healing, however small, you have already seen.',
    ],
    reflection: 'What would it look like to trust God with something still unhealed?',
  ),
  GuideContent(
    category: 'Healing',
    intro: "Healing doesn't always come on our timeline. Bring what hurts honestly, and let him carry what you can't.",
    verse: 'Beloved, I wish above all things that thou mayest prosper and be in health, even as thy soul prospereth.',
    reference: '3 John 1:2',
    prayerPoints: [
      'Pray specifically for your own body, mind, or heart today.',
      'Intercede for someone facing a diagnosis or illness.',
      "Ask for peace in a situation that medicine or time hasn't fixed yet.",
      'Thank God for the doctors, friends, and caregivers he provides.',
    ],
    reflection: "Where do you need God's healing touch most right now — even if you've prayed this before?",
  ),
  GuideContent(
    category: 'Spiritual Growth',
    intro: 'Ask God to grow roots that go deeper than a single good day — a faith that lasts.',
    verse: 'That ye might walk worthy of the Lord unto all pleasing, being fruitful in every good work, and increasing in the knowledge of God.',
    reference: 'Colossians 1:10',
    prayerPoints: [
      'Ask God to grow one specific fruit of the Spirit in you this season.',
      'Pray for discipline to stay in his Word, not just today but consistently.',
      'Ask for eyes to see where he is already at work in you.',
      'Invite him to shape a habit or attitude you have been resisting.',
    ],
    reflection: 'Where do you sense God inviting you to grow right now?',
  ),
  GuideContent(
    category: 'Spiritual Growth',
    intro: "Growth is rarely dramatic. It's showing up again tomorrow, even after a day you didn't feel like it.",
    verse: 'But grow in grace, and in the knowledge of our Lord and Saviour Jesus Christ.',
    reference: '2 Peter 3:18',
    prayerPoints: [
      'Ask God to help you finish something you started spiritually.',
      'Pray for hunger for his Word, not just discipline to read it.',
      "Ask him to prune something in your life that's crowding him out.",
      'Thank him for the growth you can already see, even if it is small.',
    ],
    reflection: "What would 'one step further' look like in your walk with God this week?",
  ),
];

/// Multiple content variants per category (not just one fixed set of
/// verse/points/reflection) so returning to the same category on a
/// different day doesn't show byte-identical content — see
/// [todaysGuide], which rotates both the category and the variant.
final Map<String, List<GuideContent>> guideContentByCategory = {
  for (final g in _guideContentList)
    g.category: [
      for (final v in _guideContentList)
        if (v.category == g.category) v,
    ],
};

enum PrayerTimeOfDay { morning, afternoon, evening }

String prayerTimeOfDayLabel(PrayerTimeOfDay t) => switch (t) {
      PrayerTimeOfDay.morning => 'Morning',
      PrayerTimeOfDay.afternoon => 'Afternoon',
      PrayerTimeOfDay.evening => 'Evening',
    };

PrayerTimeOfDay prayerTimeOfDayFor(DateTime now) {
  if (now.hour < 12) return PrayerTimeOfDay.morning;
  if (now.hour < 18) return PrayerTimeOfDay.afternoon;
  return PrayerTimeOfDay.evening;
}

/// Which categories are on-theme for each part of the day — morning leans
/// toward gratitude and worship, afternoon toward the people and needs
/// around you, evening toward reflection and growth.
const _categoriesByTimeOfDay = {
  PrayerTimeOfDay.morning: ['Thanksgiving', 'Worship'],
  PrayerTimeOfDay.afternoon: ['Family', 'Healing'],
  PrayerTimeOfDay.evening: ['Repentance', 'Spiritual Growth'],
};

/// Today's featured category and its content for "Start today's prayer" —
/// picks both from the current time of day, rotating by day of year (same
/// technique as `devotionalForDate`/`scriptureOfDayForDate`) so it's stable
/// for the whole day but changes daily rather than always defaulting to the
/// same category and text.
({GuideCategory category, GuideContent content, PrayerTimeOfDay timeOfDay})
    todaysGuide(DateTime now) {
  final timeOfDay = prayerTimeOfDayFor(now);
  final names = _categoriesByTimeOfDay[timeOfDay]!;
  final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
  final categoryName = names[dayOfYear % names.length];
  final category = guideCategories.firstWhere((g) => g.name == categoryName);
  final variants = guideContentByCategory[categoryName]!;
  final content = variants[dayOfYear % variants.length];
  return (category: category, content: content, timeOfDay: timeOfDay);
}

class ChallengeInfo {
  const ChallengeInfo(this.key, this.name, this.lengthDays, this.focusToday, this.description);
  final String key;
  final String name;
  final int lengthDays;
  final String focusToday;
  final String description;
}

const challengeCatalog = {
  'growth40': ChallengeInfo(
    'growth40',
    '40 Days of Growth',
    40,
    'Day 12 · Rooted in the Word',
    'A guided journey to deepen your walk — daily scripture, a prayer focus, and a reflection.',
  ),
  'revival30': ChallengeInfo(
    'revival30',
    '30-Day Revival',
    30,
    'Begin today',
    'Thirty days to rekindle a first-love faith through focused prayer.',
  ),
  'fast21': ChallengeInfo(
    'fast21',
    '21-Day Fasting',
    21,
    'Prepare your heart',
    'A Daniel-style fast paired with daily prayer points and prompts.',
  ),
  'jumpstart7': ChallengeInfo(
    'jumpstart7',
    '7-Day Jumpstart',
    7,
    'Start small, start today',
    'One week to build the habit — short guided sessions.',
  ),
};

// Reading plan definitions (name/length/schedule) now live in
// lib/data/bible/reading_plan_schedule.dart, generated against the real
// bundled Bible text instead of hardcoded here.

const milestoneDays = [7, 21, 30, 40, 100, 365];

const focusApps = [
  ('Instagram', Color(0xFFE4405F)),
  ('TikTok', Color(0xFF1DA1A9)),
  ('X', Color(0xFF657786)),
  ('Games', Color(0xFF8B5CF6)),
  ('Mail', Color(0xFF3B82F6)),
  ('News', Color(0xFFF97316)),
];

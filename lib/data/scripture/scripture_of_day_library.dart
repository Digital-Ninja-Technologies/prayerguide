class ScriptureOfDayEntry {
  const ScriptureOfDayEntry({
    required this.book,
    required this.chapter,
    required this.verseStart,
    required this.verseEnd,
    required this.explanation,
    required this.prayerFocus,
    required this.question,
  });

  final String book;
  final int chapter;
  final int verseStart;
  final int verseEnd;

  final String explanation;
  final String prayerFocus;
  final String question;

  String get reference => verseStart == verseEnd ? '$book $chapter:$verseStart' : '$book $chapter:$verseStart-$verseEnd';
}

/// 14 entries, cycled by day-of-year (offset from the Devotional's rotation
/// so the two features don't just mirror each other) so the Scripture of
/// the Day card and screen show something different daily without a
/// content backend. All references are verified against the bundled KJV
/// text in assets/bible/kjv.json.
const scriptureOfDayLibrary = [
  ScriptureOfDayEntry(
    book: 'Psalms',
    chapter: 46,
    verseStart: 10,
    verseEnd: 10,
    explanation:
        "In the middle of chaos, God's invitation is not to strive harder but to grow still. Stillness is where we remember who holds the world — and that it isn't us.",
    prayerFocus: 'Ask God to quiet an anxious part of your heart today, and to help you rest in his authority.',
    question: 'What are you trying to control that you could hand to God today?',
  ),
  ScriptureOfDayEntry(
    book: 'Jeremiah',
    chapter: 29,
    verseStart: 11,
    verseEnd: 11,
    explanation:
        "This promise was spoken to a people in exile, not a people whose circumstances had already turned around. God's plans for you aren't contingent on things being fine right now.",
    prayerFocus: "Thank God that his plans for your future don't depend on how today looks.",
    question: 'Where do you find it hardest to trust that God has a good future in mind for you?',
  ),
  ScriptureOfDayEntry(
    book: 'Proverbs',
    chapter: 3,
    verseStart: 5,
    verseEnd: 6,
    explanation:
        "Trusting isn't a feeling here — it's a direction. Leaning not on your own understanding means letting his voice, not your certainty, have the final word.",
    prayerFocus: 'Ask for the humility to acknowledge God in a decision you\'ve been carrying alone.',
    question: 'Where are you currently leaning on your own understanding more than on him?',
  ),
  ScriptureOfDayEntry(
    book: 'Romans',
    chapter: 8,
    verseStart: 28,
    verseEnd: 28,
    explanation:
        "This isn't a promise that everything is good — it's a promise that God is at work inside all of it, weaving even the hard things toward something.",
    prayerFocus: 'Bring something painful to God and ask him to show you where he might be working in it.',
    question: 'Is there something right now you\'re struggling to believe God could work for good?',
  ),
  ScriptureOfDayEntry(
    book: 'Isaiah',
    chapter: 41,
    verseStart: 10,
    verseEnd: 10,
    explanation:
        "Fear and dismay both assume you're facing something alone. This verse answers both at once: I am with thee, I am thy God.",
    prayerFocus: 'Name the fear you\'re carrying and ask God to remind you that you\'re not facing it alone.',
    question: 'What would change today if you truly believed God was holding you up?',
  ),
  ScriptureOfDayEntry(
    book: 'Matthew',
    chapter: 6,
    verseStart: 34,
    verseEnd: 34,
    explanation:
        "Jesus isn't telling you the future doesn't matter — he's telling you it isn't yours to carry today. Today has enough of its own.",
    prayerFocus: 'Hand tomorrow\'s worries to God and ask for grace sufficient for today alone.',
    question: 'What worry about tomorrow are you carrying that belongs to a day you\'re not in yet?',
  ),
  ScriptureOfDayEntry(
    book: 'Psalms',
    chapter: 34,
    verseStart: 18,
    verseEnd: 18,
    explanation:
        "God doesn't wait at a distance for the brokenhearted to pull themselves together. He is nigh — near — precisely to the ones who are hurting.",
    prayerFocus: 'If your heart is heavy today, ask God to make his nearness felt, not just believed.',
    question: 'Where do you need to know God is close, not just true?',
  ),
  ScriptureOfDayEntry(
    book: 'Philippians',
    chapter: 4,
    verseStart: 13,
    verseEnd: 13,
    explanation:
        "Paul wrote this from a prison cell, about learning contentment in plenty and in want — strength for endurance, not a promise of unlimited achievement.",
    prayerFocus: 'Ask for Christ\'s strength for whatever you\'re facing today, not your own.',
    question: 'What are you trying to do in your own strength that you could ask him to strengthen instead?',
  ),
  ScriptureOfDayEntry(
    book: 'Joshua',
    chapter: 1,
    verseStart: 9,
    verseEnd: 9,
    explanation:
        "Joshua was about to lead a nation into land he'd never governed. The command to be courageous was rooted in a promise, not in his own resources.",
    prayerFocus: 'Ask God for courage for something you\'ve been avoiding out of fear.',
    question: 'What is God calling you toward that requires courage you don\'t feel like you have yet?',
  ),
  ScriptureOfDayEntry(
    book: '2 Corinthians',
    chapter: 5,
    verseStart: 17,
    verseEnd: 17,
    explanation:
        "New creation isn't a slight improvement on the old self — it's a genuinely different starting point. Old things passed away; behold, all things are new.",
    prayerFocus: 'Thank God for making you new, and ask him to help you live like it today.',
    question: 'What "old thing" do you keep relating to yourself through, instead of who you\'ve become?',
  ),
  ScriptureOfDayEntry(
    book: 'Psalms',
    chapter: 23,
    verseStart: 4,
    verseEnd: 4,
    explanation:
        "The valley doesn't disappear in this psalm — the psalmist still walks through the shadow of death. What changes is who's walking with him.",
    prayerFocus: 'If you\'re in a hard season, ask God to make his presence felt as you walk through it.',
    question: 'What valley are you walking through right now, and who do you sense is with you in it?',
  ),
  ScriptureOfDayEntry(
    book: 'Galatians',
    chapter: 6,
    verseStart: 9,
    verseEnd: 9,
    explanation:
        "Well-doing has a season for reaping that isn't always visible yet. The instruction isn't to feel like it's working — it's to not grow weary before the harvest comes.",
    prayerFocus: 'Ask for endurance in something good you\'ve been tempted to give up on.',
    question: 'Where are you tempted to stop doing good because you haven\'t seen the fruit yet?',
  ),
  ScriptureOfDayEntry(
    book: 'Psalms',
    chapter: 139,
    verseStart: 14,
    verseEnd: 14,
    explanation:
        "David isn't praising his own achievements here — he's praising the craftsmanship of being made at all. Fearfully and wonderfully made, before he did anything.",
    prayerFocus: 'Thank God for how he made you, apart from anything you\'ve accomplished.',
    question: 'Where do you struggle to believe you\'re wonderfully made rather than just adequate?',
  ),
  ScriptureOfDayEntry(
    book: 'Hebrews',
    chapter: 4,
    verseStart: 16,
    verseEnd: 16,
    explanation:
        "Boldness at the throne of grace isn't arrogance — it's the confidence of someone invited in, not someone sneaking in. Mercy and grace are what's waiting there.",
    prayerFocus: 'Come to God boldly today with whatever you need, instead of hesitating at the door.',
    question: 'What are you hesitant to bring to God, as if you needed to earn the right to ask?',
  ),
];

/// Deterministic pick for [date], offset from the Devotional's rotation so
/// the two features don't mirror each other on the same day.
ScriptureOfDayEntry scriptureOfDayForDate(DateTime date) {
  final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
  return scriptureOfDayLibrary[(dayOfYear + 5) % scriptureOfDayLibrary.length];
}

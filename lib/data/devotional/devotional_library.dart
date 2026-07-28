class DevotionalEntry {
  const DevotionalEntry({
    required this.title,
    required this.book,
    required this.chapter,
    required this.verseStart,
    required this.verseEnd,
    required this.reflection,
    required this.question,
  });

  final String title;
  final String book;
  final int chapter;
  final int verseStart;
  final int verseEnd;

  /// One or two short paragraphs, separated by a blank line.
  final String reflection;
  final String question;

  String get reference => verseStart == verseEnd ? '$book $chapter:$verseStart' : '$book $chapter:$verseStart-$verseEnd';
}

/// 14 devotionals, cycled by day-of-year so the app shows a different one
/// each day without needing a content backend. All scripture references are
/// verified against the bundled KJV text in assets/bible/kjv.json.
const devotionalLibrary = [
  DevotionalEntry(
    title: 'Anchored',
    book: 'Hebrews',
    chapter: 6,
    verseStart: 19,
    verseEnd: 19,
    reflection:
        "An anchor doesn't stop the storm — it holds you steady inside it. The writer of Hebrews calls our hope in God exactly that: sure and steadfast.\n\n"
        "Whatever waves are moving your circumstances today, they don't move the One your hope is fastened to. Let that settle your heart before you pray.",
    question: 'What storm are you asking God to calm, and can you trust the anchor to hold?',
  ),
  DevotionalEntry(
    title: 'Be Still',
    book: 'Psalms',
    chapter: 46,
    verseStart: 10,
    verseEnd: 10,
    reflection:
        "In the middle of chaos, God's invitation is not to strive harder but to grow still. Stillness is where we remember who holds the world — and that it isn't us.\n\n"
        "You don't have to solve everything before you pray. You just have to stop long enough to notice who is already in the room.",
    question: 'What are you trying to control that you could hand to God today?',
  ),
  DevotionalEntry(
    title: 'Instead of Anxiety',
    book: 'Philippians',
    chapter: 4,
    verseStart: 6,
    verseEnd: 7,
    reflection:
        "Paul doesn't say pretend the worry isn't there. He says trade it — bring the very thing that's gnawing at you into prayer, with thanks mixed in even before the answer comes.\n\n"
        "What follows isn't a solution to the problem. It's a peace that doesn't wait for one — a peace that guards your heart while the problem is still unsolved.",
    question: 'Name the thing you’re anxious about. What would it look like to bring it, not just carry it?',
  ),
  DevotionalEntry(
    title: 'Renewed Strength',
    book: 'Isaiah',
    chapter: 40,
    verseStart: 31,
    verseEnd: 31,
    reflection:
        "Waiting rarely feels like strength. It feels like standing still while everyone else moves. But Isaiah ties the two together on purpose — the waiting is where the renewing happens.\n\n"
        "You don't manufacture strength for the next season. You receive it, in the waiting, from someone whose strength was never running low to begin with.",
    question: 'Where in your life does waiting feel like weakness? What if it’s where strength is being renewed?',
  ),
  DevotionalEntry(
    title: "The Shepherd's Care",
    book: 'Psalms',
    chapter: 23,
    verseStart: 1,
    verseEnd: 1,
    reflection:
        "One line, and it settles the whole psalm before it starts: if the LORD is shepherding you, want is not the posture you have to carry.\n\n"
        "Not because nothing is missing — but because the one leading you already knows what you need before you ask, and has never once lost a sheep he meant to keep.",
    question: 'What would change in your day if you actually believed you lacked nothing that mattered?',
  ),
  DevotionalEntry(
    title: 'New Every Morning',
    book: 'Lamentations',
    chapter: 3,
    verseStart: 22,
    verseEnd: 23,
    reflection:
        "Lamentations is a book of grief — and it's exactly there, in the middle of loss, that this verse shows up. Mercy that doesn't run out. Compassion renewed before the sun is even up.\n\n"
        "Whatever yesterday cost you, today isn't required to carry its weight. His faithfulness didn't get tired overnight.",
    question: 'What would it mean to receive today as genuinely new, not just yesterday continued?',
  ),
  DevotionalEntry(
    title: 'Working Together for Good',
    book: 'Romans',
    chapter: 8,
    verseStart: 28,
    verseEnd: 28,
    reflection:
        "This verse gets quoted often and felt rarely — because it doesn't promise that everything is good. It promises that God is at work inside all of it, weaving even the hard things toward something.\n\n"
        "That's not an explanation for pain. It's a reason to keep bringing the pain to him instead of carrying it alone.",
    question: 'Is there something in your life right now you’re struggling to believe God could work for good?',
  ),
  DevotionalEntry(
    title: 'Come and Rest',
    book: 'Matthew',
    chapter: 11,
    verseStart: 28,
    verseEnd: 28,
    reflection:
        "Jesus doesn't say come once you've sorted yourself out. He says come as you are — labouring, heavy laden — and I will give you rest.\n\n"
        "Rest here isn't the absence of burden. It's a person you hand the burden to, who is strong enough to actually carry it.",
    question: 'What are you laboring under right now that you haven’t actually brought to him?',
  ),
  DevotionalEntry(
    title: 'Trust and Lean Not',
    book: 'Proverbs',
    chapter: 3,
    verseStart: 5,
    verseEnd: 6,
    reflection:
        "\"Lean not unto thine own understanding\" isn't a call to stop thinking — it's a warning against making your own reasoning the final word. Understanding has limits. Trust doesn't have to.\n\n"
        "Acknowledging him in all your ways is a daily practice, not a one-time decision. It's choosing, again this morning, whose voice gets the last say.",
    question: 'Where are you currently leaning on your own understanding more than on him?',
  ),
  DevotionalEntry(
    title: 'A Different Peace',
    book: 'John',
    chapter: 14,
    verseStart: 27,
    verseEnd: 27,
    reflection:
        "Jesus is careful to distinguish his peace from the world's. The world's peace usually means the absence of a problem. His peace was given the night before he went to the cross — present in the middle of the very worst thing.\n\n"
        "That's the kind he's offering you: not the peace of nothing being wrong, but the peace of him being present regardless.",
    question: 'What would it look like to receive his peace today without waiting for the circumstances to change first?',
  ),
  DevotionalEntry(
    title: 'Strength in Weakness',
    book: '2 Corinthians',
    chapter: 12,
    verseStart: 9,
    verseEnd: 9,
    reflection:
        "Paul asked three times for his weakness to be removed. God's answer wasn't yes, and it wasn't a cold no — it was grace, sufficient, and a strength that only shows up once ours runs out.\n\n"
        "Your weakness isn't disqualifying. In this verse, it's the exact place his power chooses to rest.",
    question: 'What weakness have you been trying to hide from God instead of bringing to him?',
  ),
  DevotionalEntry(
    title: 'Where Help Comes From',
    book: 'Psalms',
    chapter: 121,
    verseStart: 1,
    verseEnd: 2,
    reflection:
        "The psalmist looks up at the hills — ancient symbols of strength and danger both — and asks the honest question: where is my help actually going to come from?\n\n"
        "The answer isn't the hills themselves. It's the one who made them. Whatever you're looking to for strength today, it was made by the one who can actually give it.",
    question: 'What have you been looking to for help that isn’t the one who made it?',
  ),
  DevotionalEntry(
    title: 'Casting Your Cares',
    book: '1 Peter',
    chapter: 5,
    verseStart: 7,
    verseEnd: 7,
    reflection:
        "Casting is a deliberate act, not a passive feeling — you throw the care, you don't just quietly hope it drifts away. And the reason given isn't that the care doesn't matter. It's that he cares about you.\n\n"
        "You're not asked to stop caring about your life. You're asked to stop carrying it alone.",
    question: 'What care have you been holding onto that you could actually cast today?',
  ),
  DevotionalEntry(
    title: 'Be Strong and Courageous',
    book: 'Joshua',
    chapter: 1,
    verseStart: 9,
    verseEnd: 9,
    reflection:
        "Joshua was about to lead a nation into land he'd never governed, against battles he hadn't fought. The command to be strong wasn't rooted in his own resources — it was rooted in a promise: wherever you go, I am with thee.\n\n"
        "Courage here isn't the absence of fear. It's remembering who's going with you before you take the next step.",
    question: 'What is God calling you toward that requires courage you don’t feel like you have yet?',
  ),
];

/// Deterministic pick for [date] — the same day always shows the same
/// devotional, and it rotates through the whole set across the year.
DevotionalEntry devotionalForDate(DateTime date) {
  final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
  return devotionalLibrary[dayOfYear % devotionalLibrary.length];
}

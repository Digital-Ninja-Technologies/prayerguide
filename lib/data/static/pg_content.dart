import 'package:flutter/material.dart';

class GuideCategory {
  const GuideCategory(this.name, this.desc, this.duration, this.teal);
  final String name;
  final String desc;
  final String duration;
  final bool teal; // true = teal accent, false = amber accent
}

const guideCategories = [
  GuideCategory('Thanksgiving', 'Begin the day in gratitude', '8 min', false),
  GuideCategory('Worship', 'Adore who God is', '10 min', true),
  GuideCategory('Repentance', 'Return with a soft heart', '7 min', true),
  GuideCategory('Family', 'Lift up those you love', '9 min', false),
  GuideCategory('Healing', 'Pray for restoration', '10 min', true),
  GuideCategory('Spiritual Growth', 'Grow deeper roots', '12 min', false),
];

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

class PgGroup {
  const PgGroup(this.name, this.members, this.meta, this.live);
  final String name;
  final String members;
  final String meta;
  final bool live;
}

const groupsCatalog = [
  PgGroup('Family Prayer', '4 members', 'Tonight · 8:00 PM', false),
  PgGroup('Tuesday Small Group', '9 members', 'Live now', true),
  PgGroup('Grace Church', '120 members', 'Wednesdays · 7:00 PM', false),
];

const focusApps = [
  ('Instagram', Color(0xFFE4405F)),
  ('TikTok', Color(0xFF1DA1A9)),
  ('X', Color(0xFF657786)),
  ('Games', Color(0xFF8B5CF6)),
  ('Mail', Color(0xFF3B82F6)),
  ('News', Color(0xFFF97316)),
];

/// Prayer minutes for the last 7 days (Sun–Sat), for the Growth Insights bar chart.
const weeklyPrayerMinutes = [22, 0, 18, 30, 12, 25, 40];

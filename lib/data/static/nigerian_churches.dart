/// A curated directory of major Nigerian churches' official YouTube
/// channels, shown on the Channel tab (`channel_screen.dart`) so users can
/// find and watch a service without knowing a channel URL up front.
/// Every URL here was checked against the channel's real, live page before
/// being added — if a ministry rebrands or moves channels, update the URL
/// here rather than trusting search results blindly.
class NigerianChurch {
  const NigerianChurch({
    required this.name,
    required this.leader,
    required this.city,
    required this.youtubeUrl,
  });

  final String name;
  final String leader;
  final String city;
  final String youtubeUrl;

  /// What the search box matches against.
  String get searchText => '$name $leader $city'.toLowerCase();
}

const kNigerianChurches = <NigerianChurch>[
  NigerianChurch(
    name: 'The Redeemed Christian Church of God (RCCG)',
    leader: 'Pastor E.A. Adeboye',
    city: 'Redemption Camp, Lagos',
    youtubeUrl: 'https://www.youtube.com/rccglive',
  ),
  NigerianChurch(
    name: 'Living Faith Church Worldwide (Winners Chapel)',
    leader: 'Bishop David Oyedepo',
    city: 'Canaanland, Ota',
    youtubeUrl: 'https://www.youtube.com/@winnerschapelLFC',
  ),
  NigerianChurch(
    name: 'Dunamis International Gospel Centre',
    leader: 'Dr. Paul Enenche',
    city: 'Abuja',
    youtubeUrl: 'https://www.youtube.com/@dunamisfamilytv',
  ),
  NigerianChurch(
    name: 'Christ Embassy (LoveWorld)',
    leader: 'Pastor Chris Oyakhilome',
    city: 'Lagos',
    youtubeUrl: 'https://www.youtube.com/@CHRISOYAKHILOME303',
  ),
  NigerianChurch(
    name: 'Mountain of Fire and Miracles Ministries (MFM)',
    leader: 'Dr. D.K. Olukoya',
    city: 'Yaba, Lagos',
    youtubeUrl: 'https://www.youtube.com/channel/UCMd5fYoenMlMJQ6-Bt6gsRw',
  ),
  NigerianChurch(
    name: 'House on the Rock',
    leader: 'Pastor Paul Adefarasin',
    city: 'Lekki, Lagos',
    youtubeUrl: 'https://www.youtube.com/user/hotrlagos',
  ),
  NigerianChurch(
    name: 'Daystar Christian Centre',
    leader: 'Pastor Sam Adeyemi',
    city: 'Lagos',
    youtubeUrl: 'https://www.youtube.com/@Daystar-NG',
  ),
  NigerianChurch(
    name: 'COZA (Commonwealth of Zion Assembly)',
    leader: 'Reverend Biodun Fatoyinbo',
    city: 'Abuja',
    youtubeUrl: 'https://www.youtube.com/channel/UClZC1vOBKGWS-ZKUpSpEvlQ',
  ),
  NigerianChurch(
    name: 'The Elevation Church',
    leader: 'Pastor Godman Akinlabi',
    city: 'Lagos',
    youtubeUrl: 'https://www.youtube.com/channel/UCB48LAzLuRMpdQ6udqrq7HQ',
  ),
  NigerianChurch(
    name: 'Covenant Nation',
    leader: 'Pastor Poju Oyemade',
    city: 'Lagos',
    youtubeUrl: 'https://www.youtube.com/channel/UCsVBRhKh9spV-YPTub0KcxQ',
  ),
  NigerianChurch(
    name: 'Deeper Christian Life Ministry',
    leader: 'Pastor W.F. Kumuyi',
    city: 'Lagos',
    youtubeUrl: 'https://www.youtube.com/@DCLMHQ',
  ),
  NigerianChurch(
    name: 'Salvation Ministries',
    leader: 'Pastor David Ibiyeomie',
    city: 'Port Harcourt',
    youtubeUrl: 'https://www.youtube.com/channel/UCH7KHtVTI91GcN6yuwvaFvQ',
  ),
  NigerianChurch(
    name: 'Celebration Church International',
    leader: 'Apostle Emmanuel Iren',
    city: 'Lagos',
    youtubeUrl: 'https://www.youtube.com/@CelebrationGlobalTV',
  ),
  NigerianChurch(
    name: 'David Christian Centre',
    leader: 'Pastor Kingsley Okonkwo',
    city: 'Lagos',
    youtubeUrl: 'https://www.youtube.com/@KingsleyOkonkwo',
  ),
  NigerianChurch(
    name: 'The Fountain of Life Church',
    leader: 'Pastor Jimmy Odukoya',
    city: 'Ilupeju, Lagos',
    youtubeUrl: 'https://www.youtube.com/jimmyodukoyaofficial',
  ),
  NigerianChurch(
    name: 'Citadel Global Community Church (formerly Latter Rain Assembly)',
    leader: 'Pastor Tunde Bakare',
    city: 'Lagos',
    youtubeUrl: 'https://www.youtube.com/channel/UCBUgX2vAE337fWGu_o6lY1w',
  ),
];

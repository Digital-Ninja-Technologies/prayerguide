import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/bible/bible_library.dart';

/// Loads the bundled KJV text once and caches it for the app's lifetime.
final bibleLibraryProvider = FutureProvider<BibleLibrary>((ref) => BibleLibrary.load());

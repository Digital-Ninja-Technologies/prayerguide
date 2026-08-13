import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/notifications/push_service.dart';
import 'core/supabase/supabase_config.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.init();
  runApp(const ProviderScope(child: PrayerGuideApp()));
  // Deliberately not awaited: this can show a native permission prompt
  // (FirebaseMessaging.requestPermission), which must never block the
  // first frame from rendering — the app should be fully interactive
  // underneath that prompt, not stuck on a blank screen waiting for it.
  unawaited(PushService.instance.init());
}

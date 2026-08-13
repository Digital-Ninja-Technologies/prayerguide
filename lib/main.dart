import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/notifications/push_service.dart';
import 'core/supabase/supabase_config.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.init();
  await PushService.instance.init();
  runApp(const ProviderScope(child: PrayerGuideApp()));
}

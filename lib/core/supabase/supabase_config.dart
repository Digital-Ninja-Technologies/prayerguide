import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static Future<void> init() async {
    await dotenv.load(fileName: '.env');
    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];
    if (url == null || url.isEmpty || anonKey == null || anonKey.isEmpty) {
      throw StateError(
        'Missing SUPABASE_URL / SUPABASE_ANON_KEY. Copy .env.example to .env '
        'and fill in your Supabase project credentials.',
      );
    }
    await Supabase.initialize(url: url, anonKey: anonKey);
  }
}

SupabaseClient get supa => Supabase.instance.client;

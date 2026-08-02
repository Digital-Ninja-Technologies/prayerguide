import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:livekit_client/livekit_client.dart';

import '../supabase/supabase_config.dart';

/// Thin wrapper around LiveKit for Audio Prayer Room voice.
///
/// Needs `LIVEKIT_URL` set in `.env` (see SETUP.md) — the API key/secret
/// used to actually mint join tokens live only in the `livekit-token`
/// Supabase Edge Function (`supabase/functions/livekit-token/`), never in
/// the app itself, since anyone could extract a client-embedded secret and
/// impersonate any room.
class LiveKitService {
  bool get isConfigured => (dotenv.env['LIVEKIT_URL'] ?? '').isNotEmpty;

  /// Requests a join token for [groupId]'s room from the `livekit-token`
  /// Edge Function, which also verifies the caller is actually a member of
  /// that group before minting one.
  Future<String> _fetchToken(String groupId) async {
    final res = await supa.functions
        .invoke('livekit-token', body: {'groupId': groupId});
    final token = (res.data as Map?)?['token'] as String?;
    if (token == null || token.isEmpty) {
      throw StateError('Could not get a voice token for this room.');
    }
    return token;
  }

  /// Connects to and joins [groupId]'s voice room with the microphone on.
  /// Caller owns the returned [Room] and must call `disconnect()`/`dispose()`
  /// when leaving.
  Future<Room> connect(String groupId) async {
    if (!isConfigured) {
      throw StateError('Voice isn\'t configured for this build yet.');
    }
    final url = dotenv.env['LIVEKIT_URL']!;
    final token = await _fetchToken(groupId);
    final room = Room();
    await room.connect(url, token);
    await room.localParticipant?.setMicrophoneEnabled(true);
    return room;
  }
}

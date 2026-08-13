import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../firebase_options.dart';
import '../router/app_router.dart';
import '../supabase/supabase_config.dart';
import '../theme/pg_colors.dart';
import '../../widgets/pg_button.dart';

/// Push notifications for "Pray with Companion" invites (see
/// prayer_invite_provider.dart) — the one notification kind SETUP.md
/// flags as needing a server-triggered push rather than a local schedule.
///
/// Needs a real Firebase project (`flutterfire configure` — see SETUP.md
/// §3d). Until then, [isConfigured] is false and [init] is a no-op, same
/// "leave it blank to disable" pattern as every other optional integration
/// in this app (RevenueCat before it was removed, LiveKit, Google Drive
/// backup) — a missing `firebase_options.dart` project id just means no
/// push, not a crash.
class PushService {
  PushService._();
  static final instance = PushService._();

  bool _initialized = false;

  bool get isConfigured =>
      !kIsWeb && DefaultFirebaseOptions.currentPlatform.projectId.isNotEmpty;

  Future<void> init() async {
    if (!isConfigured || _initialized) return;
    _initialized = true;

    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    } catch (e) {
      debugPrint('PushService: Firebase.initializeApp failed — $e');
      _initialized = false;
      return;
    }

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    supa.auth.onAuthStateChange.listen((state) {
      if (state.session != null) _registerToken();
    });
    if (supa.auth.currentUser != null) await _registerToken();
    messaging.onTokenRefresh.listen((_) => _registerToken());

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    final initial = await messaging.getInitialMessage();
    if (initial != null) _handleNotificationTap(initial);
  }

  Future<void> _registerToken() async {
    final uid = supa.auth.currentUser?.id;
    if (uid == null) return;
    String? token;
    try {
      token = await FirebaseMessaging.instance.getToken();
    } catch (e) {
      // Expected until the APNs token is available (e.g. the Push
      // Notifications capability isn't added yet, or on most simulators) —
      // same "no push, not a crash" fallback as everywhere else in this
      // file.
      debugPrint('PushService: getToken failed — $e');
      return;
    }
    if (token == null) return;
    await supa.from('device_push_tokens').upsert({
      'user_id': uid,
      'token': token,
      'platform': Platform.isIOS ? 'ios' : 'android',
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'token');
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (message.data['type'] != 'companion_prayer_invite') return;
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    _showInviteDialog(
      context,
      title: message.notification?.title ?? 'Someone wants to pray with you',
      inviteId: message.data['inviteId'] as String?,
      companionId: message.data['companionId'] as String?,
    );
  }

  /// A tap on the system notification (app was backgrounded or cold-started
  /// from it) is treated as an implicit accept — there's no interactive UI
  /// available from outside the app without native notification action
  /// buttons, which this doesn't set up.
  void _handleNotificationTap(RemoteMessage message) {
    if (message.data['type'] != 'companion_prayer_invite') return;
    final inviteId = message.data['inviteId'] as String?;
    final companionId = message.data['companionId'] as String?;
    if (companionId == null) return;
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    if (inviteId != null) {
      supa.rpc('respond_to_prayer_invite',
          params: {'invite_id': inviteId, 'new_status': 'accepted'}).catchError((_) {});
    }
    context.push('/together/$companionId');
  }

  void _showInviteDialog(
    BuildContext context, {
    required String title,
    required String? inviteId,
    required String? companionId,
  }) {
    if (inviteId == null || companionId == null) return;
    final c = context.colors;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(title),
        content: Text(
          'Tap join to pray together right now.',
          style: TextStyle(color: c.dim, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              try {
                await supa.rpc('respond_to_prayer_invite',
                    params: {'invite_id': inviteId, 'new_status': 'declined'});
              } catch (_) {}
            },
            child: Text('Not now', style: TextStyle(color: c.dim)),
          ),
          PgButton(
            label: 'Join',
            expand: false,
            dense: true,
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              try {
                await supa.rpc('respond_to_prayer_invite',
                    params: {'invite_id': inviteId, 'new_status': 'accepted'});
              } catch (_) {}
              if (context.mounted) context.push('/together/$companionId');
            },
          ),
        ],
      ),
    );
  }
}

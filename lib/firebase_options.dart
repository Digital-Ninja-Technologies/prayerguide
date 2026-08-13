// Placeholder Firebase config — push notifications (companion prayer
// invites) stay disabled until this is replaced with the real thing.
//
// To enable: create a Firebase project, add it to this app, then from the
// repo root run:
//   dart pub global activate flutterfire_cli
//   flutterfire configure
// That overwrites this entire file with your project's real values (and
// drops the platform config files it needs alongside it). See SETUP.md §3d.
//
// `PushService.isConfigured` treats a blank `projectId` as "not set up
// yet" and skips calling Firebase.initializeApp() entirely, so leaving
// this file as-is is safe — the app just won't have push notifications.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: '',
    appId: '',
    messagingSenderId: '',
    projectId: '',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: '',
    appId: '',
    messagingSenderId: '',
    projectId: '',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: '',
    appId: '',
    messagingSenderId: '',
    projectId: '',
    iosBundleId: 'com.prayerguide.prayerGuide',
  );
}

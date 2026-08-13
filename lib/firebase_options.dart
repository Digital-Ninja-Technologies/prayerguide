// Real Firebase config for the `prayerguide-128a2` project (generated via
// `flutterfire configure`) — android/ios are wired up; web is intentionally
// left blank since this app doesn't ship push notifications on web.
// Re-run `flutterfire configure` if the Firebase project ever changes.

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
    apiKey: 'AIzaSyDoVKMRnFSjvIyeUQR7hJ8y5AAiTbPJIgE',
    appId: '1:958100344013:android:7bacfbeb7b7df8f3e36d84',
    messagingSenderId: '958100344013',
    projectId: 'prayerguide-128a2',
    storageBucket: 'prayerguide-128a2.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD3HMnJDfvbMCQgyQd2hI94M-qV2f4Of8Y',
    appId: '1:958100344013:ios:7e87a2065eaab259e36d84',
    messagingSenderId: '958100344013',
    projectId: 'prayerguide-128a2',
    storageBucket: 'prayerguide-128a2.firebasestorage.app',
    iosBundleId: 'com.prayerguide.prayerGuide',
  );
}

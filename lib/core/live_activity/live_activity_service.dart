import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bridges the Prayer Timer's countdown to a real iOS Live Activity —
/// shown on the Lock Screen and, on supported hardware, the Dynamic Island
/// — via a method channel to native Swift/ActivityKit code
/// (ios/Runner/LiveActivityChannel.swift +
/// ios/PrayerTimerWidget/PrayerTimerLiveActivity.swift). See SETUP.md §3e
/// for the one-time Xcode Widget Extension target this needs.
///
/// No-ops everywhere else: Android has no OS equivalent, Live Activities
/// need iOS 16.1+, and the widget extension target itself only exists once
/// someone's added it in Xcode — none of that should ever crash a Prayer
/// Timer session, just silently mean no lock-screen countdown.
class LiveActivityService {
  LiveActivityService._();
  static final instance = LiveActivityService._();

  static const _channel = MethodChannel('com.prayerguide.prayer_guide/live_activity');

  bool get isSupported => !kIsWeb && Platform.isIOS;

  Future<void> start({required String category, required DateTime endDate}) async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod('start', {
        'category': category,
        'endDateMillis': endDate.millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint('LiveActivityService.start: $e');
    }
  }

  Future<void> updatePaused({
    required bool isPaused,
    required int remainingSeconds,
    required DateTime endDate,
  }) async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod('update', {
        'isPaused': isPaused,
        'remainingSeconds': remainingSeconds,
        'endDateMillis': endDate.millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint('LiveActivityService.update: $e');
    }
  }

  Future<void> end() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod('end');
    } catch (e) {
      debugPrint('LiveActivityService.end: $e');
    }
  }
}

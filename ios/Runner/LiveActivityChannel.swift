// Bridges lib/core/live_activity/live_activity_service.dart to ActivityKit.
// Lives in the main Runner target (only the containing app may start/
// update/end a Live Activity — the widget extension only renders it).
//
// Needs the "PrayerTimerWidget" Widget Extension target added in Xcode
// (see SETUP.md §3e) for PrayerTimerAttributes to exist and for a Live
// Activity to actually render anywhere — this channel compiles and no-ops
// safely without it, but nothing will show up on the Lock Screen/Dynamic
// Island until that target is added.

import ActivityKit
import Flutter
import Foundation

@available(iOS 16.1, *)
enum LiveActivityChannel {
  private static var currentActivity: Activity<PrayerTimerAttributes>?

  static func register(with controller: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: "com.prayerguide.prayer_guide/live_activity",
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "start":
        start(call: call, result: result)
      case "update":
        update(call: call, result: result)
      case "end":
        end(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func start(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard ActivityAuthorizationInfo().areActivitiesEnabled else {
      result(false)
      return
    }
    guard let args = call.arguments as? [String: Any],
      let category = args["category"] as? String,
      let endDateMillis = args["endDateMillis"] as? Double
    else {
      result(FlutterError(code: "bad_args", message: "Missing category/endDateMillis", details: nil))
      return
    }

    let attributes = PrayerTimerAttributes(category: category)
    let state = PrayerTimerAttributes.ContentState(
      endDate: Date(timeIntervalSince1970: endDateMillis / 1000),
      isPaused: false,
      remainingSecondsWhenPaused: 0
    )
    do {
      currentActivity = try Activity.request(
        attributes: attributes,
        content: .init(state: state, staleDate: nil)
      )
      result(true)
    } catch {
      result(FlutterError(code: "start_failed", message: error.localizedDescription, details: nil))
    }
  }

  private static func update(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let activity = currentActivity else {
      result(false)
      return
    }
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "bad_args", message: "Missing args", details: nil))
      return
    }
    let isPaused = args["isPaused"] as? Bool ?? false
    let remaining = args["remainingSeconds"] as? Int ?? 0
    let endDateMillis = args["endDateMillis"] as? Double ?? (Date().timeIntervalSince1970 * 1000)
    let state = PrayerTimerAttributes.ContentState(
      endDate: Date(timeIntervalSince1970: endDateMillis / 1000),
      isPaused: isPaused,
      remainingSecondsWhenPaused: remaining
    )
    Task {
      await activity.update(.init(state: state, staleDate: nil))
      result(true)
    }
  }

  private static func end(result: @escaping FlutterResult) {
    guard let activity = currentActivity else {
      result(false)
      return
    }
    Task {
      await activity.end(nil, dismissalPolicy: .immediate)
      currentActivity = nil
      result(true)
    }
  }
}

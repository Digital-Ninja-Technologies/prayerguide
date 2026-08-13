// Shared between the Runner app target and the PrayerTimerWidget extension
// target — add this file to BOTH targets' membership in Xcode (File
// inspector → Target Membership) once the extension target exists. See
// SETUP.md §3e.

import ActivityKit
import Foundation

struct PrayerTimerAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    /// When the countdown reaches zero — the widget renders a live,
    /// self-updating countdown from this via `Text(timerInterval:)`
    /// rather than the app pushing a new value every second.
    var endDate: Date
    var isPaused: Bool
    /// Only meaningful while paused, since `endDate` stops being accurate
    /// the moment the countdown is paused.
    var remainingSecondsWhenPaused: Int
  }

  /// The prayer category shown alongside the countdown (e.g. "Thanksgiving").
  var category: String
}

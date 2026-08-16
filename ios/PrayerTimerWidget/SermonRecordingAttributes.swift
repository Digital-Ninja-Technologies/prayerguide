// Shared between the Runner app target and the PrayerTimerWidget extension
// target — add this file to BOTH targets' membership in Xcode (File
// inspector → Target Membership), same as PrayerTimerAttributes.swift.

import ActivityKit
import Foundation

struct SermonRecordingAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    /// When the take started — elapsed time renders as a live, self-updating
    /// count-up via `Text(timerInterval:)` rather than the app pushing a new
    /// value every second. There's no fixed end (recording stops whenever
    /// the user taps stop), so the widget counts up rather than down.
    var startDate: Date
  }

  /// The sermon note's title, shown alongside the elapsed time.
  var title: String
}

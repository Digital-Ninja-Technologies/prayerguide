// The widget extension's entry point. When you create the
// "PrayerTimerWidget" target in Xcode (SETUP.md §3e), it generates a
// starter version of this file — replace its contents with this.
//
// One WidgetBundle can host multiple Live Activities — SermonRecordingLiveActivity
// was added here directly rather than as a new extension target.

import SwiftUI
import WidgetKit

@main
struct PrayerTimerWidgetBundle: WidgetBundle {
  var body: some Widget {
    PrayerTimerLiveActivity()
    SermonRecordingLiveActivity()
  }
}

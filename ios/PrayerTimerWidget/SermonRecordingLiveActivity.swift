// The Lock Screen banner + Dynamic Island presentation for an in-progress
// sermon-note recording. Lives in the PrayerTimerWidget extension target,
// registered alongside PrayerTimerLiveActivity in PrayerTimerWidgetBundle.

import ActivityKit
import SwiftUI
import WidgetKit

struct SermonRecordingLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: SermonRecordingAttributes.self) { context in
      LockScreenView(context: context)
        .activityBackgroundTint(Color.black.opacity(0.85))
        .activitySystemActionForegroundColor(Color.white)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          RecordingDot()
        }
        DynamicIslandExpandedRegion(.trailing) {
          ElapsedText(context: context)
            .font(.title3)
            .monospacedDigit()
        }
        DynamicIslandExpandedRegion(.bottom) {
          Text(context.attributes.title)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
      } compactLeading: {
        RecordingDot()
      } compactTrailing: {
        ElapsedText(context: context)
          .font(.caption2)
          .monospacedDigit()
          .frame(width: 42)
      } minimal: {
        RecordingDot()
      }
    }
  }
}

/// The recording indicator — a plain red dot rather than a pulsing one,
/// since Live Activity views are largely static snapshots (no animation
/// timers running outside the app).
private struct RecordingDot: View {
  var body: some View {
    Circle()
      .fill(Color.red)
      .frame(width: 10, height: 10)
  }
}

private struct ElapsedText: View {
  let context: ActivityViewContext<SermonRecordingAttributes>

  var body: some View {
    Text(timerInterval: context.state.startDate...Date.distantFuture, countsDown: false)
  }
}

private struct LockScreenView: View {
  let context: ActivityViewContext<SermonRecordingAttributes>

  var body: some View {
    HStack(spacing: 14) {
      RecordingDot()
      VStack(alignment: .leading, spacing: 2) {
        Text("Recording sermon note")
          .font(.caption)
          .foregroundStyle(.white.opacity(0.7))
        Text(context.attributes.title)
          .font(.subheadline)
          .bold()
          .foregroundStyle(.white)
          .lineLimit(1)
      }
      Spacer()
      ElapsedText(context: context)
        .font(.title3)
        .monospacedDigit()
        .foregroundStyle(.white)
    }
    .padding()
  }
}

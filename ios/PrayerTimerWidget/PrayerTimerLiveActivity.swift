// The actual Lock Screen banner + Dynamic Island presentations for a
// Prayer Timer session. Lives in the PrayerTimerWidget extension target —
// see SETUP.md §3e for adding that target in Xcode and wiring this file
// (and PrayerTimerAttributes.swift, shared with the Runner target) into it.

import ActivityKit
import SwiftUI
import WidgetKit

struct PrayerTimerLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: PrayerTimerAttributes.self) { context in
      LockScreenView(context: context)
        .activityBackgroundTint(Color.black.opacity(0.85))
        .activitySystemActionForegroundColor(Color.white)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Image(systemName: "hands.sparkles.fill")
            .foregroundStyle(.teal)
        }
        DynamicIslandExpandedRegion(.trailing) {
          CountdownText(context: context)
            .font(.title3)
            .monospacedDigit()
        }
        DynamicIslandExpandedRegion(.bottom) {
          Text(context.attributes.category)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      } compactLeading: {
        Image(systemName: "hands.sparkles.fill")
          .foregroundStyle(.teal)
      } compactTrailing: {
        CountdownText(context: context)
          .font(.caption2)
          .monospacedDigit()
          .frame(width: 42)
      } minimal: {
        Image(systemName: "hands.sparkles.fill")
          .foregroundStyle(.teal)
      }
    }
  }
}

/// The countdown itself — a system-rendered live timer when running (no
/// per-second updates needed from the app), or a static "Paused" label.
private struct CountdownText: View {
  let context: ActivityViewContext<PrayerTimerAttributes>

  var body: some View {
    if context.state.isPaused {
      Text(formatted(context.state.remainingSecondsWhenPaused))
    } else {
      Text(timerInterval: Date()...context.state.endDate, countsDown: true)
    }
  }

  private func formatted(_ seconds: Int) -> String {
    let m = seconds / 60
    let s = seconds % 60
    return String(format: "%d:%02d", m, s)
  }
}

private struct LockScreenView: View {
  let context: ActivityViewContext<PrayerTimerAttributes>

  var body: some View {
    HStack(spacing: 14) {
      Image(systemName: "hands.sparkles.fill")
        .font(.title2)
        .foregroundStyle(.teal)
      VStack(alignment: .leading, spacing: 2) {
        Text(context.attributes.category)
          .font(.caption)
          .foregroundStyle(.white.opacity(0.7))
        if context.state.isPaused {
          Text("Paused")
            .font(.title2)
            .bold()
            .foregroundStyle(.white)
        } else {
          CountdownText(context: context)
            .font(.title2)
            .bold()
            .foregroundStyle(.white)
        }
      }
      Spacer()
    }
    .padding()
  }
}

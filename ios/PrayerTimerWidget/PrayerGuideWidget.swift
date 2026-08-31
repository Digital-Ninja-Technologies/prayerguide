// The app's actual Home Screen / Widget Gallery widget. Everything else in
// this extension (PrayerTimerLiveActivity, SermonRecordingLiveActivity) is a
// Live Activity — those only ever appear on the Lock Screen/Dynamic Island
// while one is running, never in the Widget Gallery. Without a real
// StaticConfiguration widget like this one, the extension still declares
// itself as a `com.apple.widgetkit-extension` (required for the Live
// Activities to work at all), which led App Review to look for a
// gallery-addable widget and correctly find none (ITMS/Guideline 2.1(a)).
//
// Static — no per-day content or account data (that would need an App Group
// to bridge data from the Flutter app's process into this extension, a
// larger change than this fix calls for). Tapping it opens the app via the
// `prayerguide://guide` URL registered in Runner/Info.plist.

import SwiftUI
import WidgetKit

struct PrayerGuideEntry: TimelineEntry {
  let date: Date
}

struct PrayerGuideProvider: TimelineProvider {
  func placeholder(in context: Context) -> PrayerGuideEntry {
    PrayerGuideEntry(date: Date())
  }

  func getSnapshot(in context: Context, completion: @escaping (PrayerGuideEntry) -> Void) {
    completion(PrayerGuideEntry(date: Date()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerGuideEntry>) -> Void) {
    // Content doesn't change through the day, so a single entry with a
    // once-daily refresh is enough — no need for a denser timeline.
    let entry = PrayerGuideEntry(date: Date())
    let nextMidnight = Calendar.current.nextDate(
      after: Date(), matching: DateComponents(hour: 0, minute: 0), matchingPolicy: .nextTime
    ) ?? Date().addingTimeInterval(86400)
    completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
  }
}

private let widgetBackgroundColor = Color(red: 0.055, green: 0.082, blue: 0.075)
private let widgetTeal = Color(red: 0.357, green: 0.761, blue: 0.702)

struct PrayerGuideWidgetView: View {
  var entry: PrayerGuideProvider.Entry
  @Environment(\.widgetFamily) private var family

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Image(systemName: "flame.fill")
        .font(.title2)
        .foregroundStyle(widgetTeal)
      Spacer(minLength: 4)
      Text("Prayer Guide")
        .font(.headline)
        .foregroundStyle(.white)
      if family != .systemSmall {
        Text("Tap to start today's prayer")
          .font(.caption)
          .foregroundStyle(.white.opacity(0.7))
          .lineLimit(2)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .padding()
    .applyWidgetBackground()
  }
}

private extension View {
  /// `containerBackground` is the iOS 17+ way to set a widget's background
  /// (lets the system apply the "removable background" treatment); a plain
  /// `.background` is the iOS 16.1+ fallback — still renders correctly, it
  /// just doesn't get that treatment on 17+.
  @ViewBuilder
  func applyWidgetBackground() -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      containerBackground(widgetBackgroundColor, for: .widget)
    } else {
      background(widgetBackgroundColor)
    }
  }
}

struct PrayerGuideWidget: Widget {
  let kind: String = "PrayerGuideWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: PrayerGuideProvider()) { entry in
      PrayerGuideWidgetView(entry: entry)
        .widgetURL(URL(string: "prayerguide://guide"))
    }
    .configurationDisplayName("Prayer Guide")
    .description("Quick access to start today's prayer.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
